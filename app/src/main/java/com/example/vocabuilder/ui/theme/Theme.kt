package com.example.vocabuilder.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val LightColorScheme = lightColorScheme(
    primary = Blue40,
    onPrimary = androidx.compose.ui.graphics.Color.White,
    primaryContainer = Blue80,
    secondary = PurpleGrey40,
    onSecondary = androidx.compose.ui.graphics.Color.White,
    secondaryContainer = PurpleGrey80,
    tertiary = Green40,
    tertiaryContainer = Green80,
    error = Red40,
    surface = androidx.compose.ui.graphics.Color(0xFFFFFBFE),
    onSurface = androidx.compose.ui.graphics.Color(0xFF1C1B1F),
    surfaceVariant = androidx.compose.ui.graphics.Color(0xFFE7E0EC),
    outline = androidx.compose.ui.graphics.Color(0xFF79747E)
)

private val DarkColorScheme = darkColorScheme(
    primary = Blue80,
    onPrimary = DarkBackground,
    primaryContainer = Blue40,
    secondary = PurpleGrey80,
    onSecondary = DarkBackground,
    secondaryContainer = PurpleGrey40,
    tertiary = Green80,
    tertiaryContainer = Green40,
    error = Red80,
    surface = DarkBackground,
    onSurface = androidx.compose.ui.graphics.Color(0xFFE6E1E5),
    surfaceVariant = DarkSurfaceVariant,
    outline = androidx.compose.ui.graphics.Color(0xFF938F99)
)

@Composable
fun VocabuilderTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = colorScheme.surface.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
