part of 'runner.dart';

mixin _CleanMixin on _Melos {
  Future<void> clean({
    GlobalOptions? global,
    PackageFilters? packageFilters,
  }) async {
    final workspace =
        await createWorkspace(global: global, packageFilters: packageFilters);

    return _runLifecycle(
      workspace,
      CommandWithLifecycle.clean,
      () async {
        logger.log('Cleaning workspace...');

        await Future.wait(workspace.filteredPackages.values.map(_cleanPackage));

        await cleanIntelliJ(workspace);

        logger
          ..newLine()
          ..log(
            'Workspace cleaned. You will need to run the bootstrap command '
            'again to use this workspace.',
          );
      },
    );
  }

  Future<void> _cleanPackage(Package package) async {
    final pathsToClean = [
      ...cleanablePubFilePaths,
      '.dart_tool',
    ];

    for (final generatedPubFilePath in pathsToClean) {
      deleteEntry(p.join(package.path, generatedPubFilePath));
    }
  }

  Future<void> cleanIntelliJ(MelosWorkspace workspace) async {
    if (dirExists(workspace.ide.intelliJ.runConfigurationsDir.path)) {
      final melosXmlGlob = createGlob(
        p.join(
          workspace.ide.intelliJ.runConfigurationsDir.path,
          '$kRunConfigurationPrefix*.xml',
        ),
        currentDirectoryPath: workspace.path,
      );

      await for (final melosXmlFile
          in melosXmlGlob.listFileSystem(const LocalFileSystem())) {
        deleteEntry(melosXmlFile.path);
      }
    }
  }
}
