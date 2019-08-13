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

        // 反映させる
        File.WriteAllText(projPath, proj.WriteToString());
    }
}