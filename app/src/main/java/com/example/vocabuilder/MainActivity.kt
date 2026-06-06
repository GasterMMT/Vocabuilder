package com.example.vocabuilder

import android.content.Context
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import com.example.vocabuilder.ui.navigation.VocabuilderNavGraph
import com.example.vocabuilder.ui.theme.VocabuilderTheme
import com.example.vocabuilder.ui.util.ChineseStrings
import com.example.vocabuilder.ui.util.EnglishStrings
import com.example.vocabuilder.ui.util.LocalUiStrings

class MainActivity : ComponentActivity() {

    override fun attachBaseContext(newBase: Context?) {
        val app = VocabuilderApp.instance
        if (app.currentLanguage != "auto") {
            val locale = VocabuilderApp.languageToLocale(app.currentLanguage)
            if (locale != null) {
                val config = android.content.res.Configuration(newBase?.resources?.configuration)
                config.setLocale(locale)
                @Suppress("DEPRECATION")
                val wrapped = newBase?.createConfigurationContext(config) ?: newBase
                super.attachBaseContext(wrapped)
                return
            }
        }
        super.attachBaseContext(newBase)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        val app = VocabuilderApp.instance
        app.applyLocale(resources.configuration)

        setContent {
            val lang by app.languageFlow.collectAsState()
            val strings = when (lang) {
                "zh" -> ChineseStrings
                else -> EnglishStrings
            }

            val themeMode by app.preferencesManager.themeMode.collectAsState(initial = "system")

            val isDark = when (themeMode) {
                "light" -> false
                "dark" -> true
                else -> isSystemInDarkTheme()
            }

            CompositionLocalProvider(LocalUiStrings provides strings) {
                VocabuilderTheme(darkTheme = isDark, dynamicColor = true) {
                    Surface(
                        modifier = Modifier.fillMaxSize(),
                        color = MaterialTheme.colorScheme.background
                    ) {
                        VocabuilderNavGraph()
                    }
                }
            }
        }
    }
}
