package com.example.vocabuilder.ui.screens.importword

import android.net.Uri
import android.provider.OpenableColumns
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.RadioButtonUnchecked
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.UploadFile
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.vocabuilder.network.LlmParsedWord
import com.example.vocabuilder.ui.util.LocalUiStrings
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.InputStreamReader

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ImportScreen(
    onNavigateBack: () -> Unit,
    viewModel: ImportViewModel = viewModel(factory = ImportViewModel.Factory)
) {
    val strings = LocalUiStrings.current
    val state by viewModel.state.collectAsState()
    val books by viewModel.books.collectAsState()
    var bookDropdownExpanded by remember { mutableStateOf(false) }
    var langDropdownExpanded by remember { mutableStateOf(false) }
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    var selectedFileName by remember { mutableStateOf<String?>(null) }
    var selectedFileContent by remember { mutableStateOf<String?>(null) }
    var isProcessingFile by remember { mutableStateOf(false) }

    val languages = listOf("Chinese (中文)", "English", "Japanese (日语)", "Korean (韩语)", "Spanish (西班牙语)", "French (法语)", "German (德语)", "Russian (俄语)", "Arabic (阿拉伯语)", "Vietnamese (越南语)", "Thai (泰语)", "Portuguese (葡萄牙语)", "Italian (意大利语)")

    val filePickerLauncher = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        uri?.let {
            scope.launch {
                val name = getFileName(context, it)
                selectedFileName = name
                val content = readText(context, it)
                if (content != null) {
                    selectedFileContent = content
                    isProcessingFile = true
                    viewModel.onInputTextChanged("")
                    viewModel.parseWithFileContent(content)
                }
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(strings.importWords) },
                navigationIcon = { IconButton(onClick = onNavigateBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = strings.back) } },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.surface)
            )
        }
    ) { padding ->
        if (state.isComplete) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.padding(32.dp)) {
                    Icon(Icons.Default.CheckCircle, contentDescription = null, modifier = Modifier.size(64.dp), tint = MaterialTheme.colorScheme.tertiary)
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(strings.importComplete, style = MaterialTheme.typography.headlineSmall)
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(String.format(strings.successfullyImported, state.selectedIndices.size), style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Spacer(modifier = Modifier.height(24.dp))
                    Button(onClick = { viewModel.reset(); selectedFileName = null; selectedFileContent = null; isProcessingFile = false }) {
                        Icon(Icons.Default.Refresh, contentDescription = null, modifier = Modifier.size(18.dp)); Spacer(modifier = Modifier.width(8.dp)); Text(strings.importMore)
                    }
                }
            }
        } else {
            Column(modifier = Modifier.fillMaxSize().padding(padding).verticalScroll(rememberScrollState()).padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                // File selector
                Card(modifier = Modifier.fillMaxWidth(), colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)), shape = RoundedCornerShape(12.dp)) {
                    Column(modifier = Modifier.padding(16.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(Icons.Default.UploadFile, contentDescription = null, modifier = Modifier.size(40.dp), tint = MaterialTheme.colorScheme.primary)
                        if (selectedFileName != null) {
                            Spacer(modifier = Modifier.height(8.dp))
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Default.Description, contentDescription = null, modifier = Modifier.size(20.dp), tint = MaterialTheme.colorScheme.primary); Spacer(modifier = Modifier.width(8.dp))
                                Text(selectedFileName!!, style = MaterialTheme.typography.titleSmall)
                            }
                            if (isProcessingFile && state.isLoading) {
                                Spacer(modifier = Modifier.height(4.dp)); CircularProgressIndicator(modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
                                Text(strings.parsing, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.primary)
                            } else if (!state.isLoading && state.parsedWords.isNotEmpty()) {
                                Text(String.format(strings.parsedNWords, state.parsedWords.size), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.tertiary)
                            }
                            Spacer(modifier = Modifier.height(8.dp))
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                Button(onClick = { filePickerLauncher.launch(arrayOf("text/plain", "text/markdown")) }, colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.secondaryContainer, contentColor = MaterialTheme.colorScheme.onSecondaryContainer)) { Text(strings.selectFile) }
                                if (selectedFileContent != null && !state.isLoading) Button(onClick = { scope.launch { isProcessingFile = true; viewModel.parseWithFileContent(selectedFileContent!!) } }) { Text("Re-parse") }
                            }
                        } else {
                            Spacer(modifier = Modifier.height(8.dp))
                            Text("Select a file to import", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            Spacer(modifier = Modifier.height(12.dp))
                            Button(onClick = { filePickerLauncher.launch(arrayOf("text/plain", "text/markdown")) }) {
                                Icon(Icons.Default.UploadFile, contentDescription = null, modifier = Modifier.size(18.dp)); Spacer(modifier = Modifier.width(8.dp)); Text(strings.selectFile + " (.md, .txt)")
                            }
                        }
                    }
                }

                // Language selector
                ExposedDropdownMenuBox(expanded = langDropdownExpanded, onExpandedChange = { langDropdownExpanded = !langDropdownExpanded }) {
                    OutlinedTextField(
                        value = state.targetLanguage, onValueChange = {}, readOnly = true,
                        label = { Text(strings.targetLanguageHint) },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = langDropdownExpanded) },
                        modifier = Modifier.menuAnchor().fillMaxWidth()
                    )
                    ExposedDropdownMenu(expanded = langDropdownExpanded, onDismissRequest = { langDropdownExpanded = false }) {
                        languages.forEach { lang ->
                            DropdownMenuItem(text = { Text(lang) }, onClick = { viewModel.onTargetLanguageChanged(lang); langDropdownExpanded = false })
                        }
                    }
                }

                // Checkboxes
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.weight(1f)) { Checkbox(checked = state.includeExample, onCheckedChange = { viewModel.setIncludeExample(it) }); Text(strings.exampleSentence, style = MaterialTheme.typography.bodySmall) }
                    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.weight(1f)) { Checkbox(checked = state.includeCategory, onCheckedChange = { viewModel.setIncludeCategory(it) }); Text(strings.categoryOptional, style = MaterialTheme.typography.bodySmall) }
                    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.weight(1f)) { Checkbox(checked = state.includeNotes, onCheckedChange = { viewModel.setIncludeNotes(it) }); Text(strings.notesOptional, style = MaterialTheme.typography.bodySmall) }
                }

                // Manual text input
                Text("或手动粘贴文本：", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                OutlinedTextField(value = state.inputText, onValueChange = { viewModel.onInputTextChanged(it) }, label = { Text(strings.pasteTextHint) }, modifier = Modifier.fillMaxWidth().height(100.dp), minLines = 3, maxLines = 6)

                Button(
                    onClick = { viewModel.parseWithLLM() },
                    enabled = state.inputText.isNotBlank() && !state.isLoading,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    if (state.isLoading) { CircularProgressIndicator(modifier = Modifier.size(18.dp), strokeWidth = 2.dp, color = MaterialTheme.colorScheme.onPrimary); Spacer(modifier = Modifier.width(8.dp)) }
                    else { Icon(Icons.Default.Download, contentDescription = null, modifier = Modifier.size(18.dp)); Spacer(modifier = Modifier.width(8.dp)) }
                    Text(if (state.isLoading) strings.parsing else strings.parseWithAI)
                }

                // Error
                AnimatedVisibility(visible = state.error != null, enter = fadeIn() + expandVertically(), exit = fadeOut() + shrinkVertically()) {
                    Card(modifier = Modifier.fillMaxWidth(), colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.errorContainer)) {
                        Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.Close, contentDescription = null, tint = MaterialTheme.colorScheme.error); Spacer(modifier = Modifier.width(12.dp))
                            Text(state.error ?: "", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onErrorContainer)
                        }
                    }
                }

                // Results
                AnimatedVisibility(visible = state.parsedWords.isNotEmpty(), enter = fadeIn() + expandVertically()) {
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                            Text(String.format(strings.parsedNWords, state.parsedWords.size), style = MaterialTheme.typography.titleSmall)
                            Row { TextButton(onClick = { viewModel.selectAll() }) { Text(strings.selectAll) }; TextButton(onClick = { viewModel.deselectAll() }) { Text(strings.deselect) } }
                        }
                        ExposedDropdownMenuBox(expanded = bookDropdownExpanded, onExpandedChange = { bookDropdownExpanded = !bookDropdownExpanded }) {
                            OutlinedTextField(value = books.find { it.id == state.selectedBookId }?.name ?: strings.noBookGeneral, onValueChange = {}, readOnly = true,
                                label = { Text(strings.addToBook) }, trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = bookDropdownExpanded) }, modifier = Modifier.menuAnchor().fillMaxWidth())
                            ExposedDropdownMenu(expanded = bookDropdownExpanded, onDismissRequest = { bookDropdownExpanded = false }) {
                                DropdownMenuItem(text = { Text(strings.noBookGeneral) }, onClick = { viewModel.setSelectedBook(null); bookDropdownExpanded = false })
                                books.forEach { b -> DropdownMenuItem(text = { Text(b.name) }, onClick = { viewModel.setSelectedBook(b.id); bookDropdownExpanded = false }) }
                                DropdownMenuItem(text = { Text("+ " + strings.create) }, onClick = {
                                    bookDropdownExpanded = false
                                    viewModel.createBook("New Book")
                                })
                            }
                        }
                        state.parsedWords.forEachIndexed { i, w -> ParsedWordItem(word = w, isSelected = state.selectedIndices.contains(i), onToggle = { viewModel.toggleWordSelection(i) }) }
                        Button(onClick = { viewModel.importSelectedWords() }, modifier = Modifier.fillMaxWidth(), enabled = state.selectedIndices.isNotEmpty()) {
                            Text(String.format(strings.importNWords, state.selectedIndices.size))
                        }
                    }
                }
            }
        }
    }
}

private fun getFileName(context: android.content.Context, uri: Uri): String? {
    var name: String? = null
    try { context.contentResolver.query(uri, null, null, null, null)?.use { c -> val i = c.getColumnIndex(OpenableColumns.DISPLAY_NAME); if (i >= 0 && c.moveToFirst()) name = c.getString(i) } } catch (_: Exception) {}
    return name ?: uri.lastPathSegment
}

private suspend fun readText(context: android.content.Context, uri: Uri): String? {
    return withContext(Dispatchers.IO) {
        try { val s = context.contentResolver.openInputStream(uri) ?: return@withContext null; val r = BufferedReader(InputStreamReader(s, "UTF-8")); val c = r.readText(); r.close(); s.close(); c } catch (_: Exception) { null }
    }
}

@Composable
private fun ParsedWordItem(word: LlmParsedWord, isSelected: Boolean, onToggle: () -> Unit) {
    Card(modifier = Modifier.fillMaxWidth().clickable { onToggle() }, colors = CardDefaults.cardColors(containerColor = if (isSelected) MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f) else MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))) {
        Row(modifier = Modifier.fillMaxWidth().padding(12.dp), verticalAlignment = Alignment.Top) {
            Icon(if (isSelected) Icons.Default.CheckCircle else Icons.Default.RadioButtonUnchecked, contentDescription = null, modifier = Modifier.size(24.dp).then(Modifier.padding(top = 2.dp)), tint = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(modifier = Modifier.width(8.dp))
            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(word.term, style = MaterialTheme.typography.titleSmall, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    if (word.partOfSpeech.isNotEmpty()) { Spacer(modifier = Modifier.width(6.dp)); Text(word.partOfSpeech, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.secondary) }
                }
                Text(word.definition, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 3, overflow = TextOverflow.Ellipsis)
                if (word.exampleSentence.isNotEmpty()) { Spacer(modifier = Modifier.height(2.dp)); Text("\"${word.exampleSentence}\"", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.tertiary, maxLines = 2, overflow = TextOverflow.Ellipsis) }
            }
        }
    }
}
