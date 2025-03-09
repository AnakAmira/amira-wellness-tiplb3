package com.amirawellness.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material.MaterialTheme
import androidx.compose.material.darkColors
import androidx.compose.material.lightColors
import androidx.compose.material.ColorPalette
import androidx.compose.runtime.Composable
import androidx.compose.material.LocalContentColor
import androidx.compose.runtime.CompositionLocalProvider

/**
 * Defines the theme for the Amira Wellness Android application using Jetpack Compose.
 * 
 * This theme establishes light and dark themes with consistent colors, typography, and shapes
 * that support the application's minimalist, nature-inspired design approach aimed at
 * creating a calming environment for emotional wellness.
 */

/**
 * Light theme color palette that uses calming nature-inspired colors
 * to create a soothing and trustworthy interface for emotional wellness.
 */
val LightColorPalette = lightColors(
    primary = Primary,
    primaryVariant = PrimaryVariant,
    secondary = Secondary,
    secondaryVariant = SecondaryVariant,
    background = Background,
    surface = Surface,
    error = Error,
    onPrimary = TextOnPrimary,
    onSecondary = TextOnSecondary,
    onBackground = TextPrimary,
    onSurface = TextPrimary,
    onError = White
)

/**
 * Dark theme color palette that maintains the calming nature-inspired aesthetic
 * while reducing eye strain in low-light environments.
 */
val DarkColorPalette = darkColors(
    primary = PrimaryDark,
    primaryVariant = Primary,
    secondary = SecondaryDark,
    secondaryVariant = Secondary,
    background = BackgroundDark,
    surface = SurfaceDark,
    error = Error,
    onPrimary = TextOnPrimary,
    onSecondary = TextOnSecondary,
    onBackground = White,
    onSurface = White,
    onError = White
)

/**
 * The main theme composable for Amira Wellness application.
 * 
 * This composable applies the appropriate color palette, typography, and shapes
 * to create a cohesive, calming visual experience throughout the application.
 * The theme supports both light and dark modes to accommodate user preferences
 * and reduce eye strain in different lighting conditions.
 *
 * @param darkTheme Whether to use dark theme colors, defaults to system preference
 * @param content The content to be displayed with this theme
 */
@Composable
fun AmiraWellnessTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colors = if (darkTheme) {
        DarkColorPalette
    } else {
        LightColorPalette
    }

    MaterialTheme(
        colors = colors,
        typography = Typography,
        shapes = Shapes,
        content = {
            CompositionLocalProvider {
                content()
            }
        }
    )
}