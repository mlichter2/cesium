uniform sampler2D u_atlas;

#ifdef VECTOR_TILE
uniform vec4 u_highlightColor;
#endif

varying vec2 v_textureCoordinates;
varying vec4 v_textureOffset;
varying vec2 v_depthLookupTextureCoordinate1;
varying vec2 v_depthLookupTextureCoordinate2;
varying vec2 v_depthLookupTextureCoordinate3;
varying vec2 v_dimensions;
varying float v_eyeDepth;

#ifdef RENDER_FOR_PICK
varying vec4 v_pickColor;
#else
varying vec4 v_color;
#endif

void main()
{

#ifdef RENDER_FOR_PICK
    vec4 vertexColor = vec4(1.0, 1.0, 1.0, 1.0);
#else
    vec4 vertexColor = v_color;
#endif

    vec4 color = texture2D(u_atlas, v_textureCoordinates) * vertexColor;

// Fully transparent parts of the billboard are not pickable.
#if defined(RENDER_FOR_PICK) || (!defined(OPAQUE) && !defined(TRANSLUCENT))
    if (color.a < 0.005)   // matches 0/255 and 1/255
    {
        discard;
    }
#else
// The billboard is rendered twice. The opaque pass discards translucent fragments
// and the translucent pass discards opaque fragments.
#ifdef OPAQUE
    if (color.a < 0.995)   // matches < 254/255
    {
        discard;
    }
#else
    if (color.a >= 0.995)  // matches 254/255 and 255/255
    {
        discard;
    }
#endif
#endif

#ifdef VECTOR_TILE
    color *= u_highlightColor;
#endif

#ifdef RENDER_FOR_PICK
    gl_FragColor = v_pickColor;
#else
    gl_FragColor = color;
#endif

    czm_writeLogDepth();

    vec2 adjustedST = v_textureCoordinates - v_textureOffset.xy;
    adjustedST = adjustedST / (v_textureOffset.z - v_textureOffset.x, v_textureOffset.w - v_textureOffset.y);

    vec2 st1 = ((v_dimensions.xy * (v_depthLookupTextureCoordinate1 - adjustedST)) + gl_FragCoord.xy) / czm_viewport.zw;
    vec2 st2 = ((v_dimensions.xy * (v_depthLookupTextureCoordinate2 - adjustedST)) + gl_FragCoord.xy) / czm_viewport.zw;
    vec2 st3 = ((v_dimensions.xy * (v_depthLookupTextureCoordinate3 - adjustedST)) + gl_FragCoord.xy) / czm_viewport.zw;

    float logDepthOrDepth = czm_unpackDepth(texture2D(czm_globeDepthTexture, st1));
    vec4 eyeCoordinate = czm_windowToEyeCoordinates(gl_FragCoord.xy, logDepthOrDepth);
    float globeDepth1 = eyeCoordinate.z / eyeCoordinate.w;

    logDepthOrDepth = czm_unpackDepth(texture2D(czm_globeDepthTexture, st2));
    eyeCoordinate = czm_windowToEyeCoordinates(gl_FragCoord.xy, logDepthOrDepth);
    float globeDepth2 = eyeCoordinate.z / eyeCoordinate.w;

    logDepthOrDepth = czm_unpackDepth(texture2D(czm_globeDepthTexture, st3));
    eyeCoordinate = czm_windowToEyeCoordinates(gl_FragCoord.xy, logDepthOrDepth);
    float globeDepth3 = eyeCoordinate.z / eyeCoordinate.w;

    // negative values go into the screen
    if (globeDepth1 > v_eyeDepth && globeDepth2 > v_eyeDepth && globeDepth3 > v_eyeDepth )
    {
        discard;
    }
}
