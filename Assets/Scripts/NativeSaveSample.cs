﻿using System.Collections;
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

    [SerializeField]
    private Texture2D _texture = null;

    private void Awake()
    {
        _buffer = new RenderTexture(Screen.width, Screen.height, 0);
        _buffer.Create();

        _commandBuffer = new CommandBuffer();
        _commandBuffer.name = "CaptureScreen";

        _commandBuffer.Blit(BuiltinRenderTextureType.CurrentActive, _buffer);
    }

    private void Update()
    {
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
                Debug.Log("Will capture the screen.");

                Camera.main.AddCommandBuffer(CameraEvent.BeforeImageEffects, _commandBuffer);

                StartCoroutine(SaveTexture());
            }
        }
#endif
    }

#if UNITY_EDITOR
    private IEnumerator EditorSaveTexture()
    {
        yield return new WaitForEndOfFrame();

        Camera.main.RemoveCommandBuffer(CameraEvent.BeforeImageEffects, _commandBuffer);

        // _image.texture = _buffer;
        _image.texture = _texture;
    }
#endif

    private IEnumerator SaveTexture()
    {
        yield return new WaitForEndOfFrame();

        Debug.Log("Save texture to the file.");

        Camera.main.RemoveCommandBuffer(CameraEvent.BeforeImageEffects, _commandBuffer);

        _image.texture = _buffer;
        // _image.texture = _texture;

        // RenderBuffer buf = _buffer.colorBuffer;
        // Debug.Log("Buffer is ");
        // Debug.Log(buf);

        // System.IntPtr ptr = _buffer.GetNativeTexturePtr();
        // System.IntPtr ptr = _texture.GetNativeTexturePtr();
        System.IntPtr ptr = _buffer.colorBuffer.GetNativeRenderBufferPtr();
        Debug.Log("Pointer is ");
        Debug.Log(ptr);

        _SaveTextureImpl(ptr);
    }

    [DllImport("__Internal")]
    static private extern void _SaveTextureImpl(System.IntPtr texture);
}
