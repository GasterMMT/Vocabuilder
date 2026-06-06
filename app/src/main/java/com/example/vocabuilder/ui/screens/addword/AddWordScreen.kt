package com.example.vocabuilder.ui.screens.addword

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Button
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
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.vocabuilder.ui.util.LocalUiStrings
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddWordScreen(
    wordId: Long?,
    defaultBookId: Long? = null,
    onNavigateBack: () -> Unit,
    viewModel: AddWordViewModel = viewModel(factory = AddWordViewModel.Factory)
) {
    val strings = LocalUiStrings.current
    val existingWord by viewModel.word.collectAsState()
    val books by viewModel.books.collectAsState()
    val scope = rememberCoroutineScope()

    var term by remember { mutableStateOf("") }
    var definition by remember { mutableStateOf("") }
    var exampleSentence by remember { mutableStateOf("") }
    var category by remember { mutableStateOf("") }
    var notes by remember { mutableStateOf("") }
    var selectedBookId by remember { mutableStateOf(defaultBookId) }
    var bookDropdownExpanded by remember { mutableStateOf(false) }
    var hasLoaded by remember { mutableStateOf(false) }

    LaunchedEffect(wordId) {
        if (wordId != null && !hasLoaded) { viewModel.loadWord(wordId); hasLoaded = true }
    }

    LaunchedEffect(existingWord) {
        existingWord?.let {
            term = it.term; definition = it.definition; exampleSentence = it.exampleSentence
            category = it.category; notes = it.notes; selectedBookId = it.bookId
        }
    }

    val isEditing = wordId != null && existingWord != null

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (isEditing) strings.editWord else strings.addWord) },
                navigationIcon = { IconButton(onClick = onNavigateBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = strings.back) } },
                actions = {
                    IconButton(onClick = {
                        if (term.isNotBlank() && definition.isNotBlank()) {
                            scope.launch {
                                viewModel.saveWord(term = term.trim(), definition = definition.trim(), exampleSentence = exampleSentence.trim(), category = category.trim(), notes = notes.trim(), bookId = selectedBookId, existingId = wordId)
                                onNavigateBack()
                            }
                        }
                    }) {
                        Icon(Icons.Default.Check, contentDescription = strings.save,
                            tint = if (term.isNotBlank() && definition.isNotBlank()) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.surface)
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier.fillMaxSize().padding(padding).padding(horizontal = 16.dp).verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Spacer(modifier = Modifier.height(8.dp))
            OutlinedTextField(value = term, onValueChange = { term = it }, label = { Text(strings.wordTerm) }, modifier = Modifier.fillMaxWidth(), singleLine = true, keyboardOptions = KeyboardOptions(imeAction = ImeAction.Next))
            OutlinedTextField(value = definition, onValueChange = { definition = it }, label = { Text(strings.definitionTrans) }, modifier = Modifier.fillMaxWidth(), minLines = 2, maxLines = 4, keyboardOptions = KeyboardOptions(imeAction = ImeAction.Next))
            OutlinedTextField(value = exampleSentence, onValueChange = { exampleSentence = it }, label = { Text(strings.exampleSentence) }, modifier = Modifier.fillMaxWidth(), minLines = 2, maxLines = 4, keyboardOptions = KeyboardOptions(imeAction = ImeAction.Next))
            OutlinedTextField(value = category, onValueChange = { category = it }, label = { Text(strings.categoryOptional) }, modifier = Modifier.fillMaxWidth(), singleLine = true, placeholder = { Text("e.g. Food, Travel, Business") }, keyboardOptions = KeyboardOptions(imeAction = ImeAction.Next))

            if (books.isNotEmpty()) {
                ExposedDropdownMenuBox(
                    expanded = bookDropdownExpanded,
                    onExpandedChange = { bookDropdownExpanded = !bookDropdownExpanded }
                ) {
                    OutlinedTextField(
                        value = books.find { it.id == selectedBookId }?.name ?: strings.noBookGeneral,
                        onValueChange = {}, readOnly = true,
                        label = { Text(strings.addToBook) },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = bookDropdownExpanded) },
                        modifier = Modifier.menuAnchor().fillMaxWidth(), singleLine = true
                    )
                    ExposedDropdownMenu(expanded = bookDropdownExpanded, onDismissRequest = { bookDropdownExpanded = false }) {
                        DropdownMenuItem(text = { Text(strings.noBookGeneral) }, onClick = { selectedBookId = null; bookDropdownExpanded = false })
                        books.forEach { book ->
                            DropdownMenuItem(text = { Text(book.name) }, onClick = { selectedBookId = book.id; bookDropdownExpanded = false })
                        }
                    }
                }
            }

            OutlinedTextField(value = notes, onValueChange = { notes = it }, label = { Text(strings.notesOptional) }, modifier = Modifier.fillMaxWidth(), minLines = 2, maxLines = 5, keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done))
            Spacer(modifier = Modifier.height(16.dp))
            Button(
                onClick = {
                    if (term.isNotBlank() && definition.isNotBlank()) {
                        scope.launch {
                            viewModel.saveWord(term = term.trim(), definition = definition.trim(), exampleSentence = exampleSentence.trim(), category = category.trim(), notes = notes.trim(), bookId = selectedBookId, existingId = wordId)
                            onNavigateBack()
                        }
                    }
                },
                modifier = Modifier.fillMaxWidth(),
                enabled = term.isNotBlank() && definition.isNotBlank()
            ) { Text(if (isEditing) strings.editWord else strings.addWord) }
            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}
