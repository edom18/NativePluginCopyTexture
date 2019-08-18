using UnityEngine;
using UnityEngine.UI;
using System;
using System.Collections;
using System.Runtime.InteropServices;

public class TextureHandler : MonoBehaviour
{
    [SerializeField]
    private RawImage _image = null;

    private Texture2D _meshTexture;

    [DllImport("__Internal")]
    private static extern void FillUnityTexture(IntPtr texRef);

    void Start()
    {
        _meshTexture = new Texture2D(200, 200, TextureFormat.ARGB32, false);

        _image.texture = _meshTexture;

        IntPtr texPtr = _meshTexture.GetNativeTexturePtr();
        Debug.Log("texPtr Unity = " + texPtr);

        FillUnityTexture(texPtr);
    }
}
