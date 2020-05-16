#extension GL_EXT_shader_framebuffer_fetch : require
precision mediump float;
varying highp vec2 textureCoordinate;
uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;
vec4 blendColor(in vec4 dstColor, in vec4 srcColor)
{
    vec3 resultFore = srcColor.rgb + dstColor.rgb * (1.0 - srcColor.a);
    return vec4(resultFore.rgb, 1.0);
}

void main()
{
    vec4 bgColor = gl_LastFragData[0];
    vec4 srcColor = texture2D(inputImageTexture, textureCoordinate);
    gl_FragColor = blendColor(bgColor, srcColor);
   
}
