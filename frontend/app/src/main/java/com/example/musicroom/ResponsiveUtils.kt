package com.example.musicroom

import android.content.res.Configuration
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

@Composable
fun rememberWindowSizeClass(): WindowSizeClass {
    val configuration = LocalConfiguration.current
    val screenWidth = configuration.screenWidthDp.dp
    val screenHeight = configuration.screenHeightDp.dp
    val isLandscape = configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
    
    return WindowSizeClass(
        width = screenWidth,
        height = screenHeight,
        isLandscape = isLandscape
    )
}

data class WindowSizeClass(
    val width: Dp,
    val height: Dp,
    val isLandscape: Boolean
)

@Composable
fun rememberResponsivePadding(windowSize: WindowSizeClass): PaddingValues {
    val isSmallScreen = windowSize.width < 600.dp
    
    return PaddingValues(
        start = if (isSmallScreen) 8.dp else 16.dp,
        end = if (isSmallScreen) 8.dp else 16.dp,
        top = if (isSmallScreen) 8.dp else 16.dp,
        bottom = if (isSmallScreen) 8.dp else 16.dp
    )
}

@Composable
fun adaptiveTextStyle(
    windowSize: WindowSizeClass,
    style: TextStyle
): TextStyle {
    val fontScale = when {
        windowSize.width < 360.dp -> 0.8f
        windowSize.width < 600.dp -> 0.9f
        else -> 1f
    }
    
    return style.copy(
        fontSize = style.fontSize * fontScale
    )
}
