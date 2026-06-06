package com.example.vocabuilder.ui.screens.wordlist

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.automirrored.filled.Sort
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.CheckBox
import androidx.compose.material.icons.filled.CheckBoxOutlineBlank
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.EditNote
import androidx.compose.material.icons.filled.FileOpen
import androidx.compose.material.icons.filled.Insights
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Quiz
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.BottomAppBar
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DockedSearchBar
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.surfaceColorAtElevation
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.Dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.vocabuilder.data.entity.LlmProfile
import com.example.vocabuilder.data.entity.Word
import com.example.vocabuilder.ui.util.LocalUiStrings
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun WordListScreen(
    onNavigateToAddWord: (Long, Long) -> Unit,
    onNavigateToFlashcard: (Long?, String, Int?) -> Unit,
    onNavigateToQuiz: () -> Unit,
    onNavigateToStats: () -> Unit,
    onNavigateToSettings: () -> Unit,
    onNavigateToImport: () -> Unit,
    viewModel: WordListViewModel = viewModel(factory = WordListViewModel.Factory)
) {
    val strings = LocalUiStrings.current
    val words by viewModel.words.collectAsState()
    val categories by viewModel.categories.collectAsState()
    val books by viewModel.books.collectAsState()
    val totalCount by viewModel.totalWordCount.collectAsState()
    val searchQuery by viewModel.searchQuery.collectAsState()
    val selectedCategories by viewModel.selectedCategories.collectAsState()
    val selectedBookId by viewModel.selectedBookId.collectAsState()
    val llmProfiles by viewModel.llmProfiles.collectAsState()
    val activeProfileId by viewModel.activeProfileId.collectAsState()
    val selectedWordIds by viewModel.selectedWordIds.collectAsState()
    val isSelectionMode by viewModel.isSelectionMode.collectAsState()

    var isSearchActive by remember { mutableStateOf(false) }
    var bookDropdownExpanded by remember { mutableStateOf(false) }
    var moreMenuExpanded by remember { mutableStateOf(false) }
    var fabMenuExpanded by remember { mutableStateOf(false) }
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    var showAddBookDialog by remember { mutableStateOf(false) }
    var newBookName by remember { mutableStateOf("") }
    var showProfileDialog by remember { mutableStateOf(false) }
    var editingProfile by remember { mutableStateOf<LlmProfile?>(null) }
    var showReviewDialog by remember { mutableStateOf(false) }
    var showDrawer by remember { mutableStateOf(false) }
    var showSortMenu by remember { mutableStateOf(false) }

    val exportLauncher = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("application/json")) { uri ->
        uri?.let { scope.launch { val n = books.find { it.id == selectedBookId }?.name ?: "all_words"; writeToUri(context, uri, buildExportJson(n, viewModel.getWordsForExport(selectedBookId))) } }
    }
    val importJsonLauncher = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        uri?.let { scope.launch { val c = readFileFromUri(context, it); if (c != null) viewModel.importWordsFromJson(c, selectedBookId) } }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { },
                actions = {
                    IconButton(onClick = { showSortMenu = true }) {
                        Icon(Icons.AutoMirrored.Filled.Sort, contentDescription = "Sort", tint = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    if (isSearchActive) IconButton(onClick = { viewModel.onSearchQueryChanged(""); isSearchActive = false }) { Icon(Icons.Default.Close, contentDescription = strings.closeSearch) }
                    else IconButton(onClick = { isSearchActive = true }) { Icon(Icons.Default.Search, contentDescription = strings.search) }
                    IconButton(onClick = { showDrawer = true }) { Icon(Icons.Default.MoreVert, contentDescription = "Menu") }
                    DropdownMenu(expanded = showSortMenu, onDismissRequest = { showSortMenu = false }) {
                        DropdownMenuItem(text = { Text("A - Z") }, onClick = { viewModel.setSortMode(0); showSortMenu = false })
                        DropdownMenuItem(text = { Text("Z - A") }, onClick = { viewModel.setSortMode(1); showSortMenu = false })
                        DropdownMenuItem(text = { Text(strings.changeFile) }, onClick = { viewModel.setSortMode(2); showSortMenu = false })
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.surface)
            )
        },
        floatingActionButton = {
            Column(horizontalAlignment = Alignment.End) {
                AnimatedVisibility(visible = fabMenuExpanded, enter = fadeIn() + slideInVertically(), exit = fadeOut() + slideOutVertically()) {
                    Column(horizontalAlignment = Alignment.End) {
                        Card(modifier = Modifier.widthIn(max = 260.dp), shape = RoundedCornerShape(16.dp), elevation = CardDefaults.cardElevation(6.dp), colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceContainerHigh)) {
                            Column(modifier = Modifier.padding(4.dp)) {
                                Row(modifier = Modifier.fillMaxWidth().clickable { fabMenuExpanded = false; onNavigateToAddWord(-1L, selectedBookId ?: -1L) }.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                                    Icon(Icons.Default.EditNote, contentDescription = null, modifier = Modifier.size(22.dp), tint = MaterialTheme.colorScheme.primary); Spacer(modifier = Modifier.width(10.dp)); Text(strings.addWord, maxLines = 1, style = MaterialTheme.typography.bodyMedium)
                                }
                                Row(modifier = Modifier.fillMaxWidth().clickable { fabMenuExpanded = false; onNavigateToImport() }.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                                    Icon(Icons.Default.AutoAwesome, contentDescription = null, modifier = Modifier.size(22.dp), tint = MaterialTheme.colorScheme.tertiary); Spacer(modifier = Modifier.width(10.dp)); Text("AI " + strings.importWords, maxLines = 1, style = MaterialTheme.typography.bodyMedium)
                                }
                                Row(modifier = Modifier.fillMaxWidth().clickable { fabMenuExpanded = false; importJsonLauncher.launch(arrayOf("application/json")) }.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                                    Icon(Icons.Default.FileOpen, contentDescription = null, modifier = Modifier.size(22.dp), tint = MaterialTheme.colorScheme.secondary); Spacer(modifier = Modifier.width(10.dp)); Text(strings.importWordBookJson, maxLines = 1, style = MaterialTheme.typography.bodyMedium)
                                }
                            }
                        }
                        Spacer(modifier = Modifier.height(12.dp))
                    }
                }
                FloatingActionButton(onClick = { fabMenuExpanded = !fabMenuExpanded }, containerColor = MaterialTheme.colorScheme.primaryContainer) {
                    Icon(if (fabMenuExpanded) Icons.Default.Close else Icons.Default.Add, contentDescription = strings.addWord, tint = MaterialTheme.colorScheme.onPrimaryContainer)
                }
            }
        },
        bottomBar = {
            AnimatedVisibility(visible = isSelectionMode, enter = slideInVertically { it }, exit = slideOutVertically { it }) {
                var showMoveBookDialog by remember { mutableStateOf(false) }
                BottomAppBar(containerColor = MaterialTheme.colorScheme.primaryContainer, tonalElevation = 4.dp) {
                    Row(modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                        TextButton(onClick = { viewModel.clearSelection() }) { Text(strings.cancel) }
                        Text("${selectedWordIds.size} " + strings.selected, style = MaterialTheme.typography.bodyMedium)
                        Row {
                            TextButton(onClick = { viewModel.deleteSelected(selectedBookId) }) { Text(strings.delete, color = MaterialTheme.colorScheme.error) }
                            TextButton(onClick = { viewModel.selectAllVisible() }) { Text(strings.selectAll) }
                            TextButton(onClick = { showMoveBookDialog = true }) { Text(strings.moveToBook) }
                        }
                    }
                }
                if (showMoveBookDialog) {
                    AlertDialog(onDismissRequest = { showMoveBookDialog = false }, title = { Text(strings.moveToBook) }, text = {
                        Column {
                            Text(String.format(strings.selectBookToMove, selectedWordIds.size), style = MaterialTheme.typography.bodyMedium)
                            Spacer(modifier = Modifier.height(12.dp))
                            OutlinedButton(onClick = { viewModel.moveSelectedToBook(null); showMoveBookDialog = false }, modifier = Modifier.fillMaxWidth()) { Text(strings.noBookGeneral) }
                            books.forEach { book -> Spacer(modifier = Modifier.height(4.dp)); OutlinedButton(onClick = { viewModel.moveSelectedToBook(book.id); showMoveBookDialog = false }, modifier = Modifier.fillMaxWidth()) { Text(book.name) } }
                            Spacer(modifier = Modifier.height(4.dp))
                            OutlinedButton(onClick = { showMoveBookDialog = false; newBookName = ""; showAddBookDialog = true }, modifier = Modifier.fillMaxWidth()) {
                                Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(16.dp)); Spacer(modifier = Modifier.width(4.dp)); Text(strings.create)
                            }
                        }
                    }, confirmButton = {}, dismissButton = { TextButton(onClick = { showMoveBookDialog = false }) { Text(strings.cancel) } })
                }
            }
        }
    ) { padding ->
        Column(modifier = Modifier.fillMaxSize().padding(padding)) {
            AnimatedVisibility(visible = isSearchActive, enter = fadeIn() + slideInVertically(), exit = fadeOut() + slideOutVertically()) {
                DockedSearchBar(query = searchQuery, onQueryChange = { viewModel.onSearchQueryChanged(it) }, onSearch = {}, active = false, onActiveChange = {},
                    placeholder = { Text(strings.searchWords) }, leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) },
                    trailingIcon = { if (searchQuery.isNotEmpty()) IconButton(onClick = { viewModel.onSearchQueryChanged("") }) { Icon(Icons.Default.Close, contentDescription = strings.clear) } },
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp)) { }
            }
            // Book selector
            Row(modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                ExposedDropdownMenuBox(expanded = bookDropdownExpanded, onExpandedChange = { bookDropdownExpanded = !bookDropdownExpanded }, modifier = Modifier.weight(1f)) {
                    OutlinedTextField(value = books.find { it.id == selectedBookId }?.name ?: strings.allWords, onValueChange = {}, readOnly = true, label = { Text(strings.wordBook) },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = bookDropdownExpanded) }, modifier = Modifier.menuAnchor().fillMaxWidth(), singleLine = true,
                        shape = RoundedCornerShape(12.dp))
                    ExposedDropdownMenu(expanded = bookDropdownExpanded, onDismissRequest = { bookDropdownExpanded = false }) {
                        DropdownMenuItem(text = { Text(strings.allWords) }, onClick = { viewModel.onBookSelected(null); bookDropdownExpanded = false })
                        books.forEach { book -> DropdownMenuItem(text = { Text(book.name) }, onClick = { viewModel.onBookSelected(book.id); bookDropdownExpanded = false }) }
                    }
                }
                Box {
                    IconButton(onClick = { moreMenuExpanded = true }) { Icon(Icons.Default.MoreVert, contentDescription = "More") }
                    DropdownMenu(expanded = moreMenuExpanded, onDismissRequest = { moreMenuExpanded = false }) {
                        DropdownMenuItem(text = { Text(strings.exportBook) }, onClick = { moreMenuExpanded = false; val name = if (selectedBookId != null) (books.find { it.id == selectedBookId }?.name ?: "book") else "all_words"; exportLauncher.launch("${name.replace(" ", "_")}.json") })
                    }
                }
            }
            // Action buttons
            Row(modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                ActionButton(strings.review, Icons.AutoMirrored.Filled.MenuBook, enabled = totalCount > 0, modifier = Modifier.weight(1f)) { showReviewDialog = true }
                ActionButton(strings.quiz, Icons.Default.Quiz, enabled = totalCount >= 4, modifier = Modifier.weight(1f), onClick = onNavigateToQuiz)
                ActionButton(strings.stats, Icons.Default.Insights, modifier = Modifier.weight(1f), onClick = onNavigateToStats)
            }
            // Category chips
            if (categories.isNotEmpty()) {
                FlowRow(modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp), horizontalArrangement = Arrangement.spacedBy(6.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    categories.forEach { cat -> FilterChip(selected = selectedCategories.contains(cat), onClick = { viewModel.onCategoryToggled(cat) }, label = { Text(cat) }, colors = FilterChipDefaults.filterChipColors(selectedContainerColor = MaterialTheme.colorScheme.primaryContainer)) }
                }
            }
            Spacer(modifier = Modifier.height(4.dp))
            // Word list
            if (words.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(if (searchQuery.isNotEmpty()) strings.noMatching else strings.noWords, style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(if (searchQuery.isNotEmpty()) strings.tryDifferentSearch else strings.tapPlusToAdd, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            } else {
                AnimatedContent(targetState = selectedBookId, transitionSpec = { fadeIn() togetherWith fadeOut() }) {
                    LazyColumn(contentPadding = PaddingValues(horizontal = 16.dp, vertical = 4.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        items(words, key = { it.id }) { word ->
                            WordListItem(word = word, isSelected = selectedWordIds.contains(word.id), isSelectionMode = isSelectionMode,
                                onClick = { if (isSelectionMode) viewModel.toggleWordSelection(word.id) else onNavigateToAddWord(word.id, selectedBookId ?: -1L) },
                                onLongClick = { viewModel.toggleWordSelection(word.id) })
                        }
                        item { Spacer(modifier = Modifier.height(80.dp)) }
                    }
                }
            }
        }
    }

    // Drawer
    if (showDrawer) {
        AlertDialog(onDismissRequest = { showDrawer = false }, title = { Text("Menu") }, text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
                Text(strings.wordBooks, style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)
                books.forEach { book ->
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                        Text(book.name, style = MaterialTheme.typography.bodyMedium)
                        IconButton(onClick = { viewModel.deleteBook(book) }, modifier = Modifier.size(28.dp)) { Icon(Icons.Default.Delete, contentDescription = strings.delete, modifier = Modifier.size(16.dp), tint = MaterialTheme.colorScheme.error.copy(alpha = 0.6f)) }
                    }
                }
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    OutlinedButton(onClick = { newBookName = ""; showAddBookDialog = true }, modifier = Modifier.fillMaxWidth()) { Icon(Icons.Default.Add, null, Modifier.size(14.dp)); Spacer(Modifier.width(4.dp)); Text(strings.create) }
                    OutlinedButton(onClick = { showDrawer = false; importJsonLauncher.launch(arrayOf("application/json")) }, modifier = Modifier.fillMaxWidth()) { Icon(Icons.Default.FileOpen, null, Modifier.size(14.dp)); Spacer(Modifier.width(4.dp)); Text(strings.importWordBookJson, maxLines = 1) }
                }
                Spacer(Modifier.height(4.dp))
                Text(strings.llmApiConfig, style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.primary)
                llmProfiles.forEach { profile ->
                    val isActive = profile.id == activeProfileId
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                        Column(modifier = Modifier.weight(1f).clickable { viewModel.setActiveProfile(profile.id) }) {
                                Row(verticalAlignment = Alignment.CenterVertically) { if (isActive) { Icon(Icons.Default.CheckBox, null, Modifier.size(14.dp), tint = MaterialTheme.colorScheme.primary); Spacer(Modifier.width(4.dp)) }; Text(profile.name, style = MaterialTheme.typography.bodyMedium) }
                            Text(profile.model, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        IconButton(onClick = { viewModel.deleteLlmProfile(profile) }, modifier = Modifier.size(28.dp)) { Icon(Icons.Default.Delete, null, Modifier.size(16.dp), tint = MaterialTheme.colorScheme.error.copy(alpha = 0.6f)) }
                        IconButton(onClick = { editingProfile = profile; showProfileDialog = true }, modifier = Modifier.size(28.dp)) { Icon(Icons.Default.Edit, null, Modifier.size(16.dp)) }
                    }
                }
                OutlinedButton(onClick = { editingProfile = LlmProfile(); showProfileDialog = true }, modifier = Modifier.fillMaxWidth()) { Icon(Icons.Default.Add, null, Modifier.size(14.dp)); Spacer(Modifier.width(4.dp)); Text(strings.addProfile) }
                Spacer(Modifier.height(4.dp))
                OutlinedButton(onClick = { showDrawer = false; onNavigateToSettings() }, modifier = Modifier.fillMaxWidth()) { Text(strings.settings) }
            }
        }, confirmButton = {}, dismissButton = { TextButton(onClick = { showDrawer = false }) { Text(strings.cancel) } })
    }

    // Add book dialog
    if (showAddBookDialog) {
        AlertDialog(onDismissRequest = { showAddBookDialog = false }, title = { Text(strings.newWordBook) }, text = {
            Column { OutlinedTextField(value = newBookName, onValueChange = { newBookName = it }, label = { Text(strings.bookName) }, singleLine = true, modifier = Modifier.fillMaxWidth()) }
        }, confirmButton = { TextButton(onClick = { if (newBookName.isNotBlank()) { viewModel.createBook(newBookName); showAddBookDialog = false } }) { Text(strings.create) } }, dismissButton = { TextButton(onClick = { showAddBookDialog = false }) { Text(strings.cancel) } })
    }

    // Profile dialog
    if (showProfileDialog && editingProfile != null) {
        var pn by remember { mutableStateOf(editingProfile!!.name) }; var pu by remember { mutableStateOf(editingProfile!!.baseUrl) }; var pk by remember { mutableStateOf(editingProfile!!.apiKey) }; var pm by remember { mutableStateOf(editingProfile!!.model) }
        AlertDialog(onDismissRequest = { showProfileDialog = false }, title = { Text("Profile") }, text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(value = pn, onValueChange = { pn = it }, label = { Text("Name") }, singleLine = true, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(value = pu, onValueChange = { pu = it }, label = { Text(strings.apiBaseUrl) }, singleLine = true, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(value = pk, onValueChange = { pk = it }, label = { Text(strings.apiKey) }, singleLine = true, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(value = pm, onValueChange = { pm = it }, label = { Text(strings.modelName) }, singleLine = true, modifier = Modifier.fillMaxWidth())
            }
        }, confirmButton = { TextButton(onClick = { viewModel.saveProfile(editingProfile!!.copy(name = pn, baseUrl = pu, apiKey = pk, model = pm)); showProfileDialog = false }) { Text(strings.save) } }, dismissButton = { TextButton(onClick = { showProfileDialog = false }) { Text(strings.cancel) } })
    }

    // Review dialog
    if (showReviewDialog) {
        var localMode by remember { mutableStateOf("all") }; var localBookId by remember { mutableStateOf(selectedBookId) }; var localCount by remember { mutableStateOf("") }; var lbExpanded by remember { mutableStateOf(false) }
        AlertDialog(onDismissRequest = { showReviewDialog = false }, title = { Text(strings.reviewOptions) }, text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(strings.reviewModeLabel, style = MaterialTheme.typography.labelLarge)
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FilterChip(selected = localMode == "all", onClick = { localMode = "all" }, label = { Text(strings.allWords) })
                    FilterChip(selected = localMode == "book", onClick = { localMode = "book" }, label = { Text(strings.wordBook) })
                }
                if (localMode == "book" && books.isNotEmpty()) {
                    ExposedDropdownMenuBox(expanded = lbExpanded, onExpandedChange = { lbExpanded = !lbExpanded }) {
                        OutlinedTextField(value = books.find { it.id == localBookId }?.name ?: books.first().name, onValueChange = {}, readOnly = true, label = { Text(strings.wordBook) }, trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = lbExpanded) }, modifier = Modifier.menuAnchor().fillMaxWidth())
                        ExposedDropdownMenu(expanded = lbExpanded, onDismissRequest = { lbExpanded = false }) { books.forEach { b -> DropdownMenuItem(text = { Text(b.name) }, onClick = { localBookId = b.id; lbExpanded = false }) } }
                    }
                }
                Text(strings.countLabel, style = MaterialTheme.typography.labelLarge)
                OutlinedTextField(value = localCount, onValueChange = { localCount = it.filter { c -> c.isDigit() } }, label = { Text(strings.countHint) }, singleLine = true, modifier = Modifier.fillMaxWidth())
            }
        }, confirmButton = { TextButton(onClick = { showReviewDialog = false; onNavigateToFlashcard(if (localMode == "book") localBookId else null, "all", localCount.toIntOrNull()) }) { Text(strings.start) } }, dismissButton = { TextButton(onClick = { showReviewDialog = false }) { Text(strings.cancel) } })
    }
}

@Composable
private fun ActionButton(label: String, icon: androidx.compose.ui.graphics.vector.ImageVector, enabled: Boolean = true, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Card(modifier = modifier.height(52.dp).let { if (enabled) it.clickable { onClick() } else it }, shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = if (enabled) MaterialTheme.colorScheme.surfaceVariant else MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f))) {
        Row(modifier = Modifier.fillMaxSize().padding(horizontal = 12.dp), horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
            Icon(icon, contentDescription = null, modifier = Modifier.size(20.dp), tint = if (enabled) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f))
            Spacer(modifier = Modifier.width(8.dp))
            Text(label, style = MaterialTheme.typography.labelLarge, color = if (enabled) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f))
        }
    }
}

private suspend fun buildExportJson(bookName: String, words: List<Word>): String {
    val json = JSONObject(); json.put("bookName", bookName); json.put("exportDate", java.time.LocalDate.now().toString())
    val arr = JSONArray(); words.forEach { w -> val o = JSONObject(); o.put("term", w.term); o.put("definition", w.definition); o.put("exampleSentence", w.exampleSentence); o.put("category", w.category); o.put("notes", w.notes); arr.put(o) }
    json.put("words", arr); return json.toString(2)
}

private suspend fun writeToUri(context: android.content.Context, uri: Uri, content: String) {
    withContext(Dispatchers.IO) { try { context.contentResolver.openOutputStream(uri)?.use { s -> OutputStreamWriter(s, "UTF-8").use { w -> w.write(content) } } } catch (_: Exception) {} }
}

private suspend fun readFileFromUri(context: android.content.Context, uri: Uri): String? {
    return withContext(Dispatchers.IO) { try { val i = context.contentResolver.openInputStream(uri) ?: return@withContext null; val r = BufferedReader(InputStreamReader(i, "UTF-8")); val c = r.readText(); r.close(); i.close(); c } catch (e: Exception) { null } }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun WordListItem(word: Word, isSelected: Boolean, isSelectionMode: Boolean, onClick: () -> Unit, onLongClick: () -> Unit) {
    val strings = LocalUiStrings.current
    Card(modifier = Modifier.fillMaxWidth().combinedClickable(onClick = onClick, onLongClick = onLongClick), shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = if (isSelected) MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.5f) else MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f))) {
        Row(modifier = Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 12.dp), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
            if (isSelectionMode) { Icon(if (isSelected) Icons.Default.CheckBox else Icons.Default.CheckBoxOutlineBlank, contentDescription = null, modifier = Modifier.size(22.dp), tint = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant); Spacer(modifier = Modifier.width(10.dp)) }
            Column(modifier = Modifier.weight(1f)) {
                Text(word.term, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Medium, maxLines = 1, overflow = TextOverflow.Ellipsis)
                Spacer(modifier = Modifier.height(2.dp))
                Text(word.definition, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 2, overflow = TextOverflow.Ellipsis)
                if (word.category.isNotEmpty()) { Spacer(modifier = Modifier.height(4.dp)); Text(word.category, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.primary) }
                if (word.consecutiveCorrect >= 3) { Spacer(modifier = Modifier.height(2.dp)); Text(strings.learned, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.tertiary, fontWeight = FontWeight.Medium) }
            }
        }
    }
}
