package com.example.vocabuilder.ui.screens.flashcard

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Celebration
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.SkipNext
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.vocabuilder.ui.util.LocalUiStrings

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FlashcardScreen(
    bookId: Long?,
    mode: String,
    limit: Int?,
    onNavigateBack: () -> Unit,
    onNavigateToQuiz: () -> Unit,
    viewModel: FlashcardViewModel = viewModel(factory = FlashcardViewModel.factory(bookId, mode, limit))
) {
    val strings = LocalUiStrings.current
    val state by viewModel.state.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(strings.flashcardReview) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = strings.back)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.surface)
            )
        }
    ) { padding ->
        Column(modifier = Modifier.fillMaxSize().padding(padding)) {
            if (state.isLoading) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text(strings.loading, style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            } else if (state.isComplete) {
                FlashcardCompleteView(state = state, onReset = { viewModel.resetAndReload() }, onGoToQuiz = onNavigateToQuiz)
            } else if (state.words.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(Icons.Default.Celebration, contentDescription = null, modifier = Modifier.size(64.dp), tint = MaterialTheme.colorScheme.primary)
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(strings.allCaughtUp, style = MaterialTheme.typography.headlineSmall)
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(strings.noWordsToReview, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center)
                        Spacer(modifier = Modifier.height(24.dp))
                        Button(onClick = onNavigateBack) { Text(strings.goBack) }
                    }
                }
            } else {
                Column(modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)) {
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text("${state.currentIndex + 1} / ${state.totalCount}", style = MaterialTheme.typography.labelLarge)
                        Text("${strings.known}: ${state.knownCount}", style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.primary)
                    }
                    Spacer(modifier = Modifier.height(4.dp))
                    LinearProgressIndicator(progress = { if (state.totalCount > 0) (state.currentIndex + 1).toFloat() / state.totalCount else 0f }, modifier = Modifier.fillMaxWidth())
                }
                Spacer(modifier = Modifier.height(16.dp))
                Box(modifier = Modifier.fillMaxWidth().weight(1f).padding(horizontal = 24.dp)) {
                    FlashcardView(term = state.words[state.currentIndex].term, definition = state.words[state.currentIndex].definition, exampleSentence = state.words[state.currentIndex].exampleSentence, isFlipped = state.isFlipped, onFlip = { viewModel.flipCard() })
                }
                AnimatedVisibility(visible = state.isFlipped) {
                    Column(modifier = Modifier.fillMaxWidth().padding(16.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(strings.howWell, style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        Spacer(modifier = Modifier.height(8.dp))
                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            RatingButton(label = strings.forgot, color = MaterialTheme.colorScheme.error, onClick = { viewModel.rateWord(1) }, modifier = Modifier.weight(1f))
                            RatingButton(label = strings.hard, color = Color(0xFFFF9800), onClick = { viewModel.rateWord(2) }, modifier = Modifier.weight(1f))
                            RatingButton(label = strings.good, color = MaterialTheme.colorScheme.primary, onClick = { viewModel.rateWord(4) }, modifier = Modifier.weight(1f))
                            RatingButton(label = strings.easy, color = MaterialTheme.colorScheme.tertiary, onClick = { viewModel.rateWord(5) }, modifier = Modifier.weight(1f))
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                        SkipButton(onClick = { viewModel.skipWord() }) {
                            Icon(Icons.Default.SkipNext, contentDescription = null, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(strings.skip)
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun FlashcardView(term: String, definition: String, exampleSentence: String, isFlipped: Boolean, onFlip: () -> Unit) {
    val strings = LocalUiStrings.current
    AnimatedContent(
        targetState = isFlipped,
        transitionSpec = { (fadeIn(tween(300)) + scaleIn()) togetherWith (fadeOut(tween(300)) + scaleOut()) },
        label = "card_flip"
    ) { flipped ->
        Box(
            modifier = Modifier.fillMaxSize().shadow(8.dp, RoundedCornerShape(24.dp)).clip(RoundedCornerShape(24.dp))
                .background(if (flipped) Brush.linearGradient(listOf(MaterialTheme.colorScheme.primaryContainer, MaterialTheme.colorScheme.secondaryContainer)) else Brush.linearGradient(listOf(MaterialTheme.colorScheme.surfaceVariant, MaterialTheme.colorScheme.surface)))
                .clickable { onFlip() },
            contentAlignment = Alignment.Center
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.padding(24.dp)) {
                if (!flipped) {
                    Text(text = term, style = MaterialTheme.typography.displayMedium, textAlign = TextAlign.Center, color = MaterialTheme.colorScheme.onSurface)
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(text = strings.tapToReveal, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                } else {
                    Text(text = definition, style = MaterialTheme.typography.headlineMedium, textAlign = TextAlign.Center, color = MaterialTheme.colorScheme.onPrimaryContainer)
                    if (exampleSentence.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(text = "\"$exampleSentence\"", style = MaterialTheme.typography.bodyLarge, textAlign = TextAlign.Center, color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f))
                    }
                }
            }
        }
    }
}

@Composable
fun RatingButton(label: String, color: Color, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Button(onClick = onClick, modifier = modifier, colors = ButtonDefaults.buttonColors(containerColor = color.copy(alpha = 0.2f), contentColor = color)) {
        Text(label, style = MaterialTheme.typography.labelMedium)
    }
}

@Composable
fun FlashcardCompleteView(state: FlashcardState, onReset: () -> Unit, onGoToQuiz: () -> Unit) {
    val strings = LocalUiStrings.current
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(Icons.Default.Celebration, contentDescription = null, modifier = Modifier.size(64.dp), tint = MaterialTheme.colorScheme.tertiary)
            Spacer(modifier = Modifier.height(16.dp))
            Text(strings.reviewComplete, style = MaterialTheme.typography.headlineSmall)
            Spacer(modifier = Modifier.height(8.dp))
            Text("${strings.known}: ${state.knownCount} / ${state.reviewedCount}", style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.primary)
            Spacer(modifier = Modifier.height(32.dp))
            Button(onClick = onReset) {
                Icon(Icons.Default.Refresh, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(modifier = Modifier.width(8.dp))
                Text(strings.reviewAgain)
            }
            Spacer(modifier = Modifier.height(12.dp))
            Button(onClick = onGoToQuiz) {
                Icon(Icons.Default.ChevronRight, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(modifier = Modifier.width(8.dp))
                Text(strings.takeQuiz)
            }
        }
    }
}

@Composable
private fun SkipButton(onClick: () -> Unit, content: @Composable () -> Unit) {
    Button(onClick = onClick, colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.surfaceVariant, contentColor = MaterialTheme.colorScheme.onSurfaceVariant)) {
        content()
    }
}
