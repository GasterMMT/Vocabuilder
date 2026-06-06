package com.example.vocabuilder.ui.screens.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.vocabuilder.VocabuilderApp
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class SettingsState(val language: String = "auto", val themeMode: String = "system")

class SettingsViewModel : ViewModel() {
    private val prefs = VocabuilderApp.instance.preferencesManager

    val state: StateFlow<SettingsState> = combine(prefs.language, prefs.themeMode) { lang, theme ->
        SettingsState(lang, theme)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), SettingsState())

    fun setLanguage(lang: String) { viewModelScope.launch { prefs.setLanguage(lang) } }
    fun setThemeMode(mode: String) { viewModelScope.launch { prefs.setThemeMode(mode) } }

    companion object {
        val Factory: ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T = SettingsViewModel() as T
        }
    }
}
