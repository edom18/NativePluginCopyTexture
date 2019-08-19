using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Rendering;

public class NativeTextureSaver : MonoBehaviour
{
    [SerializeField, Tooltip("For preview the render texture.")]
    private RawImage _image = null;

    private RenderTexture _buffer = null;
    private CommandBuffer _commandBuffer = null;

    private bool _isSaving = false;
    private YieldInstruction _waitForEndOfFrame = new WaitForEndOfFrame();

    #region ### MonoBehaviour ###
    private void Awake()
    {
        _AttachPlugin();
        SetupBuffer();
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
            StartSaveTexture();
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
    #endregion ### MonoBehaviour ###

    /// <summary>
    /// Set up a command buffer for capturing the scene.
    /// </summary>
    private void SetupBuffer()
    {
        _commandBuffer = new CommandBuffer();
        _commandBuffer.name = "CaptureScreen";

        _buffer = new RenderTexture(Screen.width, Screen.height, 0);
        _buffer.Create();

        _commandBuffer.Blit(BuiltinRenderTextureType.CurrentActive, _buffer);
    }

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
        yield return _waitForEndOfFrame;

        Debug.Log("Save texture to the file.");

        Camera.main.RemoveCommandBuffer(CameraEvent.BeforeImageEffects, _commandBuffer);

        _image.texture = _buffer;

        RenderTexture tmp = RenderTexture.active;
        RenderTexture.active = _buffer;

        // ReadPixels needs to be called for uploading buffer data to the GPU (Maybe I think)
        // If you delete these lines, the native plugin will miss to load pixels from the buffer.
        Texture2D texture = new Texture2D(_buffer.width, _buffer.height, TextureFormat.RGBA32, false);
        texture.ReadPixels(new Rect(0, 0, Screen.width, Screen.height), 0, 0, false);
        RenderTexture.active = tmp;

        // Use texture if needed.
        // This demo don't have to use the texture so destroy it immediatory.
        Destroy(texture);

        Debug.Log("Will show the texture.");

        _SaveTextureImpl(_buffer.GetNativeTexturePtr());

        _isSaving = false;
    }

#if UNITY_EDITOR
    static private void _AttachPlugin() { }
    static private void _SaveTextureImpl(System.IntPtr texture) { }
#elif UNITY_IOS
    [DllImport("__Internal")]
    static private extern void _AttachPlugin();

    [DllImport("__Internal")]
    static private extern void _SaveTextureImpl(System.IntPtr texture);
#endif
}
