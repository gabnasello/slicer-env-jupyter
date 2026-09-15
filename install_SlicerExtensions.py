# SlicerDockers/slicer-plus/install-slicer-extension.py
# https://github.com/pieper/SlicerDockers/blob/master/slicer-plus/install-slicer-extension.py

def install_slicer_extension(extensionName):
    """
    Install Slicer Extension from terminal
    
    Function adapted from

    https://github.com/Slicer/SlicerDocker/blob/main/slicer-notebook/install.sh
    
    """

    print(f"installing {extensionName}")
    manager = slicer.app.extensionsManagerModel()

    if int(slicer.app.revision) >= 30893:
        # Slicer-5.0.3 or later
        manager.updateExtensionsMetadataFromServer(True, True)
        if not manager.downloadAndInstallExtensionByName(extensionName, True):
            raise ValueError(f"Failed to install {extensionName} extension")
        # Wait for installation to complete
        # (in Slicer-5.4 downloadAndInstallExtensionByName has a waitForComplete flag
        # so that could be enabled instead of running this wait loop)
        import time
        while not manager.isExtensionInstalled(extensionName):
            slicer.app.processEvents()
            time.sleep(0.1)


if __name__ == '__main__':

    extension_list= ['SlicerJupyter',
                     'SlicerDcm2nii',
                     'Sandbox',
                     'RawImageGuess',
                     'SurfaceWrapSolidify',
                     'MarkupsToModel',
                     'SegmentEditorExtraEffects', 
                     'SlicerIGT',
                     'Auto3dgm',
                     'SlicerMorph',
                     'SegmentMesher',
                     'EasyClip']

    for pckg in extension_list:

        install_slicer_extension(pckg)
        
    quit()