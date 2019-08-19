using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Rendering;

public class NativeSaveSample : MonoBehaviour
{
    [SerializeField]
    private RawImage _image = null;

    private RenderTexture _buffer = null;
    private CommandBuffer _commandBuffer = null;

    private Texture2D _texture = null;
    private bool _isSaving = false;

    private void Awake()
    {
#if !UNITY_EDITOR
        _AttachPlugin();
#endif

        // System.IntPtr ptr = _GetNativeTexturePtr(Screen.width, Screen.height);

        // if (ptr == System.IntPtr.Zero)
        // {
        //     Debug.Log("Returned pointer is null.");
        // }
        // else
        // {
        //     _texture = Texture2D.CreateExternalTexture(Screen.width, Screen.height, TextureFormat.BGRA32, false, false, ptr);
        // }

        _buffer = new RenderTexture(Screen.width, Screen.height, 0);
        _buffer.Create();

        _commandBuffer = new CommandBuffer();
        _commandBuffer.name = "CaptureScreen";

        _commandBuffer.Blit(BuiltinRenderTextureType.CurrentActive, _buffer);
    }

    private void Update()
    {
        if (_isSaving)
        {
            return;
        }

#if UNITY_EDITOR
        if (Input.GetMouseButtonDown(0))
        {
            Camera.main.AddCommandBuffer(CameraEvent.BeforeImageEffects, _commandBuffer);
            StartCoroutine(EditorSaveTexture());
        }
#else
        if (Input.touchCount > 0)
        {
            Touch touch = Input.GetTouch(0);
            if (touch.phase == TouchPhase.Began)
            {
                StartSaveTexture();
            }
        }
#endif
    }

#if UNITY_EDITOR
    private IEnumerator EditorSaveTexture()
    {
        yield return new WaitForEndOfFrame();

        Camera.main.RemoveCommandBuffer(CameraEvent.BeforeImageEffects, _commandBuffer);

        _image.texture = _buffer;
        // _image.texture = _texture;
    }
#endif

    private void StartSaveTexture()
    {
        if (_isSaving)
        {
            return;
        }

        _isSaving = true;

        Debug.Log("Will capture the screen.");

        Camera.main.AddCommandBuffer(CameraEvent.BeforeImageEffects, _commandBuffer);

        StartCoroutine(SaveTexture());
    }

    private IEnumerator SaveTexture()
    {
        yield return new WaitForEndOfFrame();

        Debug.Log("Save texture to the file.");

        Camera.main.RemoveCommandBuffer(CameraEvent.BeforeImageEffects, _commandBuffer);

        _image.texture = _buffer;

        RenderTexture tmp = RenderTexture.active;
        RenderTexture.active = _buffer;

        Texture2D texture = new Texture2D(_buffer.width, _buffer.height, TextureFormat.RGBA32, false);
        texture.ReadPixels(new Rect(0, 0, Screen.width, Screen.height), 0, 0, false);
        RenderTexture.active = tmp;

        Debug.Log("Will show the texture.");

        _SaveTextureImpl(_buffer.GetNativeTexturePtr());

        _isSaving = false;

        // GL.InvalidateState();
    }

    [DllImport("__Internal")]
    static private extern void _SaveTextureImpl(System.IntPtr texture);

    [DllImport("__Internal")]
    static private extern void _AttachPlugin();

    [DllImport("__Internal")]
    static private extern System.IntPtr _GetNativeTexturePtr(int width, int height);
}
