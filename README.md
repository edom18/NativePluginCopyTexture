# This project save a Unity generated texture as MTLTexture through native side

This project shows you what how to save a Unity generated texture by native side.


## How to use

You should copy `Plugin/iOS/` folder to your project. You might also use `NativeTextureSaver.cs`. It is good way to use or custom this plugin.

The plugin's main implementation is `void _SaveTextureImpl(unsigned char* mtlTexture, const char* objectName, const char* methodName)`.
