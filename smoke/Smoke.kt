package smoke

import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateOf
import kotlinx.serialization.Serializable

// Each plugin leaves a mark the smoke test looks for: the serialization
// plugin writes Route$$serializer, and the compose plugin adds a Composer
// parameter to Counter.

@Serializable
data class Route(val id: Int)

@Composable
fun Counter(start: Int): Int {
    val count = mutableStateOf(start)
    return count.value + Route(1).id
}

fun describe(): String = java.lang.String.valueOf(Route(2))
