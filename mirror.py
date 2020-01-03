import os
import warnings
from subprocess import Popen, PIPE

import argparse
from git import Repo


class CommandLineException(Exception):
    pass


class TagFormatError(Exception):
    """
    Exception for cases when tag is not formatted correctly
    """

    def __init__(self, message):
        message = "Tag {} is not formatted correctly." \
                  "The tags should start with container name" \
                  " followed by version and separated by :. " \
                  "Example: bwa-v0.0.1".format(message)
        # self.message = message

        super(TagFormatError, self).__init__(message)


class InvalidTag(Exception):
    """
    Exception for cases when tag doesnt pass validation
    """


def parse_container_name(container_name):
    container_name_split = container_name.strip('/').split('/')

    assert len(container_name_split) == 2

    namespace = container_name_split[0]
    container_name = container_name_split[1]

    return namespace, container_name


def check_if_tag_valid(container_name, version):
    """
    :param container_name: name of container
    :type container_name: str
    :param version: version string
    :type version: ver
    """
    namespace, container_name = parse_container_name(container_name)

    list_of_all_dirs = get_immediate_subdirectories(os.path.join(os.getcwd(), namespace))
    if container_name not in list_of_all_dirs:
        error_str = 'Could not find directory corresponding to' \
                    ' container {}. Please check the container ' \
                    'name in tag'.format(container_name)
        raise InvalidTag(error_str)

    if not version.startswith('v'):
        raise InvalidTag('versions should start with v')

    version = version.split('.')
    if len(version) > 3 and not version[-1].startswith('rc'):
        warnings.warn('please follow semantic versioning guidelines')


def get_immediate_subdirectories(dirpath):
    """
    :param dirpath: path to main dir
    :type dirpath: str
    :return: all subdirs
    :rtype: list of str
    """
    directories = []
    for filesystem_node in os.listdir(dirpath):
        if os.path.isdir(os.path.join(dirpath, filesystem_node)):
            directories.append(filesystem_node)

    return directories


def get_containers():
    """
    :return: container and version for latest tag in repo
    :rtype: tuple of str
    """
    # Get the tags from the repository
    repo = Repo(os.getcwd())
    tags = sorted(repo.tags, key=lambda t: t.commit.committed_datetime)

    containers = []

    for tag in tags:
        tag = str(tag)
        if not len(tag.split('-')) == 2:
            raise TagFormatError(tag)

        container_name, version = tag.split('-')
        container_name = container_name.lower()

        containers.append((container_name, version))

    return containers


def run_cmd(cmd, output=None):
    """
    run command with subprocess,
    write stdout to output file if set
    :param cmd: command args
    :type cmd: list of str
    :param output: filepath for stdout
    :type output: str
    """
    stdout = None
    if output:
        stdout = open(output, "w")

    p = Popen(cmd, stdout=stdout, stderr=PIPE)

    cmdout, cmderr = p.communicate()

    retc = p.returncode

    if retc:
        raise CommandLineException(
            "command failed. stderr:{}, stdout:{}".format(
                cmdout,
                cmderr))

    if output:
        stdout.close()


def docker_pull_and_push(
        source, destination, containers
):
    """
    :param container_name: name of container to build
    :type container_name: str
    :param registry_url: url for registry to push to
    :type registry_url: str
    :param version: version string to tag container with
    :type version: str
    :param prefix: prefix to add to container name
    :type prefix: str
    """

    for container, version in containers:
        check_if_tag_valid(container, version)

        source_container = '{}/{}:{}'.format(source, container, version)
        dest_container = '{}/{}:{}'.format(destination, container, version)

        command = ['docker', 'pull', source_container]
        run_cmd(command)

        command = ['docker', 'tag', source_container, dest_container]
        run_cmd(command)

        command = ['docker', 'push', dest_container]
        run_cmd(command)


def main(args):
    containers = get_containers()
    docker_pull_and_push(
        args.source,
        args.destination,
        containers
    )


def parse_args():
    """
    specify and parse args
    """
    parser = argparse.ArgumentParser(
        description='''build and push docker containers'''
    )

    parser.add_argument('--source',
                        required=True,
                        )
    parser.add_argument('--destination',
                        required=True,
                        )

    args = parser.parse_args()

    return args


if __name__ == "__main__":
    args = parse_args()

    main(args)

