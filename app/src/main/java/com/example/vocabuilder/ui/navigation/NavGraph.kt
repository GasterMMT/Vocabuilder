package com.example.vocabuilder.ui.navigation

import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.core.tween
import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.example.vocabuilder.ui.screens.addword.AddWordScreen
import com.example.vocabuilder.ui.screens.flashcard.FlashcardScreen
import com.example.vocabuilder.ui.screens.importword.ImportScreen
import com.example.vocabuilder.ui.screens.quiz.QuizScreen
import com.example.vocabuilder.ui.screens.quiz.QuizResultScreen
import com.example.vocabuilder.ui.screens.settings.SettingsScreen
import com.example.vocabuilder.ui.screens.stats.StatsScreen
import com.example.vocabuilder.ui.screens.wordlist.WordListScreen

sealed class Screen(val route: String) {
    object WordList : Screen("word_list")
    object AddWord : Screen("add_word?wordId={wordId}&bookId={bookId}") {
        fun createRoute(wordId: Long = -1L, bookId: Long = -1L) = "add_word?wordId=$wordId&bookId=$bookId"
    }
    object Flashcard : Screen("flashcard?bookId={bookId}&mode={mode}&count={count}") {
        fun createRoute(bookId: Long = -1L, mode: String = "due", count: Int = 0) = "flashcard?bookId=$bookId&mode=$mode&count=$count"
    }
    object Quiz : Screen("quiz")
    object QuizResult : Screen("quiz_result/{score}/{total}") {
        fun createRoute(score: Int, total: Int) = "quiz_result/$score/$total"
    }
    object Stats : Screen("stats")
    object Settings : Screen("settings")
    object Import : Screen("import")
}

@Composable
fun VocabuilderNavGraph(
    navController: NavHostController = rememberNavController()
) {
    NavHost(
        navController = navController,
        startDestination = Screen.WordList.route,
        enterTransition = {
            slideIntoContainer(
                AnimatedContentTransitionScope.SlideDirection.Left,
                animationSpec = tween(300)
            )
        },
        exitTransition = {
            slideOutOfContainer(
                AnimatedContentTransitionScope.SlideDirection.Left,
                animationSpec = tween(300)
            )
        },
        popEnterTransition = {
            slideIntoContainer(
                AnimatedContentTransitionScope.SlideDirection.Right,
                animationSpec = tween(300)
            )
        },
        popExitTransition = {
            slideOutOfContainer(
                AnimatedContentTransitionScope.SlideDirection.Right,
                animationSpec = tween(300)
            )
        }
    ) {
        composable(Screen.WordList.route) {
            WordListScreen(
                onNavigateToAddWord = { wordId, bookId ->
                    navController.navigate(Screen.AddWord.createRoute(wordId, bookId))
                },
                onNavigateToFlashcard = { bookId, mode, count ->
                    navController.navigate(Screen.Flashcard.createRoute(bookId ?: -1L, mode, count ?: 0))
                },
                onNavigateToQuiz = {
                    navController.navigate(Screen.Quiz.route)
                },
                onNavigateToStats = {
                    navController.navigate(Screen.Stats.route)
                },
                onNavigateToSettings = {
                    navController.navigate(Screen.Settings.route)
                },
                onNavigateToImport = {
                    navController.navigate(Screen.Import.route)
                }
            )
        }

        composable(
            route = Screen.AddWord.route,
            arguments = listOf(
                navArgument("wordId") { type = NavType.LongType; defaultValue = -1L },
                navArgument("bookId") { type = NavType.LongType; defaultValue = -1L }
            )
        ) { backStackEntry ->
            val wordId = backStackEntry.arguments?.getLong("wordId") ?: -1L
            val bookId = backStackEntry.arguments?.getLong("bookId") ?: -1L
            AddWordScreen(
                wordId = if (wordId == -1L) null else wordId,
                defaultBookId = if (bookId == -1L) null else bookId,
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(
            route = Screen.Flashcard.route,
            arguments = listOf(
                navArgument("bookId") { type = NavType.LongType; defaultValue = -1L },
                navArgument("mode") { type = NavType.StringType; defaultValue = "due" },
                navArgument("count") { type = NavType.IntType; defaultValue = 0 }
            )
        ) {
            val bookId = it.arguments?.getLong("bookId")?.let { if (it == -1L) null else it }
            val mode = it.arguments?.getString("mode") ?: "due"
            val count = it.arguments?.getInt("count")?.let { if (it == 0) null else it }
            FlashcardScreen(
                bookId = bookId,
                mode = mode,
                limit = count,
                onNavigateBack = { navController.popBackStack() },
                onNavigateToQuiz = { navController.navigate(Screen.Quiz.route) }
            )
        }

        composable(Screen.Quiz.route) {
            QuizScreen(
                onNavigateBack = { navController.popBackStack() },
                onQuizComplete = { score, total ->
                    navController.navigate(Screen.QuizResult.createRoute(score, total)) {
                        popUpTo(Screen.Quiz.route) { inclusive = true }
                    }
                }
            )
        }

        composable(
            route = Screen.QuizResult.route,
            arguments = listOf(
                navArgument("score") { type = NavType.IntType },
                navArgument("total") { type = NavType.IntType }
            )
        ) { backStackEntry ->
            val score = backStackEntry.arguments?.getInt("score") ?: 0
            val total = backStackEntry.arguments?.getInt("total") ?: 0
            QuizResultScreen(
                score = score,
                total = total,
                onNavigateToHome = {
                    navController.popBackStack(Screen.WordList.route, false)
                },
                onRetry = {
                    navController.popBackStack()
                    navController.navigate(Screen.Quiz.route)
                }
            )
        }

        composable(Screen.Stats.route) {
            StatsScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(Screen.Settings.route) {
            SettingsScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(Screen.Import.route) {
            ImportScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }
    }
}
