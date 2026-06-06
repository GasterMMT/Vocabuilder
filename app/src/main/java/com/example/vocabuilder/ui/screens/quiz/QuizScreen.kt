package com.example.vocabuilder.ui.screens.quiz

import androidx.compose.animation.AnimatedVisibility
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Done
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.School
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.vocabuilder.ui.util.LocalUiStrings

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun QuizScreen(
    onNavigateBack: () -> Unit,
    onQuizComplete: (Int, Int) -> Unit,
    viewModel: QuizViewModel = viewModel(factory = QuizViewModel.Factory)
) {
    val strings = LocalUiStrings.current
    val state by viewModel.state.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(strings.quiz) },
                navigationIcon = { IconButton(onClick = onNavigateBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = strings.back) } },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.surface)
            )
        }
    ) { padding ->
        Column(modifier = Modifier.fillMaxSize().padding(padding)) {
            if (state.isLoading) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text(strings.preparingQuiz, style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            } else if (state.isComplete && state.questions.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(Icons.Default.School, contentDescription = null, modifier = Modifier.size(64.dp), tint = MaterialTheme.colorScheme.primary)
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(strings.notEnoughWords, style = MaterialTheme.typography.headlineSmall)
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(strings.needAtLeast4, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center)
                        Spacer(modifier = Modifier.height(24.dp))
                        Button(onClick = onNavigateBack) { Text(strings.goBack) }
                    }
                }
            } else if (state.isComplete) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(Icons.Default.EmojiEvents, contentDescription = null, modifier = Modifier.size(64.dp), tint = MaterialTheme.colorScheme.tertiary)
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(strings.quizComplete, style = MaterialTheme.typography.headlineSmall)
                        Spacer(modifier = Modifier.height(8.dp))
                        Text("${strings.score}: ${state.score} / ${state.totalQuestions}", style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.primary)
                        Spacer(modifier = Modifier.height(24.dp))
                        Button(onClick = { onQuizComplete(state.score, state.totalQuestions) }) { Text(strings.viewResults) }
                        Spacer(modifier = Modifier.height(12.dp))
                        Button(onClick = { viewModel.resetQuiz() }) {
                            Icon(Icons.Default.Refresh, contentDescription = null, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(strings.retryQuiz)
                        }
                    }
                }
            } else {
                val question = state.questions[state.currentIndex]
                Column(modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)) {
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text("${strings.question} ${state.currentIndex + 1} / ${state.totalQuestions}", style = MaterialTheme.typography.labelLarge)
                        Text("${strings.score}: ${state.score}", style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.primary)
                    }
                    Spacer(modifier = Modifier.height(4.dp))
                    LinearProgressIndicator(progress = { (state.currentIndex + 1).toFloat() / state.totalQuestions }, modifier = Modifier.fillMaxWidth())
                }
                Spacer(modifier = Modifier.height(24.dp))
                Card(
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)),
                    shape = RoundedCornerShape(16.dp)
                ) {
                    Column(modifier = Modifier.fillMaxWidth().padding(24.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(text = strings.whatIsMeaning, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(text = question.correctWord.term, style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center)
                    }
                }
                Spacer(modifier = Modifier.height(24.dp))
                Column(modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    question.options.forEachIndexed { index, option ->
                        QuizOption(
                            text = option, index = index, isSelected = state.selectedAnswer == index,
                            isCorrect = index == question.correctIndex, showResult = state.isAnswered,
                            enabled = !state.isAnswered, onClick = { viewModel.selectAnswer(index) }
                        )
                    }
                }
                Spacer(modifier = Modifier.weight(1f))
                AnimatedVisibility(visible = state.isAnswered, modifier = Modifier.fillMaxWidth().padding(16.dp)) {
                    Button(onClick = { viewModel.nextQuestion() }, modifier = Modifier.fillMaxWidth()) {
                        Text(if (state.currentIndex < state.totalQuestions - 1) strings.nextQuestion else strings.finishQuiz)
                    }
                }
            }
        }
    }
}

@Composable
fun QuizOption(text: String, index: Int, isSelected: Boolean, isCorrect: Boolean, showResult: Boolean, enabled: Boolean, onClick: () -> Unit) {
    val containerColor = when {
        !showResult -> MaterialTheme.colorScheme.surfaceVariant
        isCorrect -> MaterialTheme.colorScheme.tertiary.copy(alpha = 0.3f)
        isSelected && !isCorrect -> MaterialTheme.colorScheme.error.copy(alpha = 0.3f)
        else -> MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
    }
    Card(
        modifier = Modifier.fillMaxWidth().clickable(enabled = enabled) { onClick() },
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = containerColor)
    ) {
        Row(modifier = Modifier.fillMaxWidth().padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(modifier = Modifier.size(36.dp).clip(CircleShape).background(
                when { !showResult -> MaterialTheme.colorScheme.surfaceVariant; isCorrect -> MaterialTheme.colorScheme.tertiary.copy(alpha = 0.2f); isSelected && !isCorrect -> MaterialTheme.colorScheme.error.copy(alpha = 0.2f); else -> MaterialTheme.colorScheme.surfaceVariant }
            ), contentAlignment = Alignment.Center) {
                when {
                    showResult && isCorrect -> Icon(Icons.Default.Done, contentDescription = null, tint = MaterialTheme.colorScheme.tertiary, modifier = Modifier.size(20.dp))
                    showResult && isSelected && !isCorrect -> Icon(Icons.Default.Close, contentDescription = null, tint = MaterialTheme.colorScheme.error, modifier = Modifier.size(20.dp))
                    else -> Text(text = "${'A' + index}", style = MaterialTheme.typography.labelLarge)
                }
            }
            Spacer(modifier = Modifier.width(12.dp))
            Text(text = text, style = MaterialTheme.typography.bodyLarge, modifier = Modifier.weight(1f))
        }
    }
}

@Composable
fun QuizResultScreen(score: Int, total: Int, onNavigateToHome: () -> Unit, onRetry: () -> Unit) {
    val strings = LocalUiStrings.current
    val percentage = if (total > 0) (score.toFloat() / total * 100).toInt() else 0
    val emoji = when { percentage >= 90 -> "\uD83C\uDFC6"; percentage >= 70 -> "\uD83C\uDF89"; percentage >= 50 -> "\uD83D\uDC4D"; else -> "\uD83D\uDCAA" }
    val message = when { percentage >= 90 -> strings.excellent; percentage >= 70 -> strings.greatJob; percentage >= 50 -> strings.goodEffort; else -> strings.keepPracticing }

    Column(modifier = Modifier.fillMaxSize().padding(32.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
        Text(text = emoji, style = MaterialTheme.typography.displayLarge)
        Spacer(modifier = Modifier.height(16.dp))
        Text(text = message, style = MaterialTheme.typography.headlineLarge)
        Spacer(modifier = Modifier.height(8.dp))
        Text(text = "$score / $total correct", style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.primary)
        Spacer(modifier = Modifier.height(4.dp))
        Text(text = "$percentage%", style = MaterialTheme.typography.headlineMedium, color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Bold)
        Spacer(modifier = Modifier.height(48.dp))
        Button(onClick = onRetry, modifier = Modifier.fillMaxWidth()) {
            Icon(Icons.Default.Refresh, contentDescription = null, modifier = Modifier.size(18.dp))
            Spacer(modifier = Modifier.width(8.dp))
            Text(strings.tryAgain)
        }
        Spacer(modifier = Modifier.height(12.dp))
        Button(onClick = onNavigateToHome, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.secondaryContainer, contentColor = MaterialTheme.colorScheme.onSecondaryContainer)) {
            Text(strings.backToHome)
        }
    }
}
