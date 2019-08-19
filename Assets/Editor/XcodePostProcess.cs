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

        // フレームワークを追加する
        proj.AddFrameworkToProject(target, "Photos.framework", false);
        proj.AddBuildProperty(target, "SWIFT_VERSION", "4.0");
        proj.AddBuildProperty(target, "SWIFT_OBJC_BRIDGING_HEADER", "$(SRCROOT)/Libraries/Plugins/iOS/Bridge-Header.h");

        // 反映させる
        File.WriteAllText(projPath, proj.WriteToString());
    }
}