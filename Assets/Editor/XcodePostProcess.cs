using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEditor;
using UnityEditor.Callbacks;
using UnityEditor.iOS.Xcode;

public class XcodePostProcess : MonoBehaviour
{
    [PostProcessBuild]
    static public void OnPostProcessBuild(BuildTarget buildTarget, string path)
    {
        if (buildTarget != BuildTarget.iOS)
        {
            return;
        }

        string projPath = PBXProject.GetPBXProjectPath(path);
        PBXProject proj = new PBXProject();
        proj.ReadFromString(File.ReadAllText(projPath));

        string target = proj.TargetGuidByName("Unity-iPhone");

        // Add a framework.
        proj.AddFrameworkToProject(target, "Photos.framework", false);

        // Add settings for Swift.
        proj.AddBuildProperty(target, "SWIFT_VERSION", "4.0");
        proj.AddBuildProperty(target, "SWIFT_OBJC_BRIDGING_HEADER", "$(SRCROOT)/Libraries/Plugins/iOS/Bridge-Header.h");

        // Write back the settings.
        File.WriteAllText(projPath, proj.WriteToString());

        SetupPlist(path);
    }

    /// <summary>
    /// Set up Info.plist.
    /// </summary>
    /// <param name="path">Project path.</param>
    static private void SetupPlist(string path)
    {
        string plistPath = Path.Combine(path, "Info.plist");
        PlistDocument plist = new PlistDocument();
        plist.ReadFromFile(plistPath);

        if (!plist.root.values.ContainsKey("NSPhotoLibraryAddUsageDescription"))
        {
            plist.root.SetString("NSPhotoLibraryAddUsageDescription", "Use library for saving a texture.");
        }

        plist.WriteToFile(plistPath);
    }
}