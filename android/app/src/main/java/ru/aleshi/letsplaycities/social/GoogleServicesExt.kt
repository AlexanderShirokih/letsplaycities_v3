package ru.aleshi.letsplaycities.social

import com.google.android.gms.tasks.Task
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * Contains extension methods useful for GMS tasks
 */
object GoogleServicesExt {

    @JvmName("awaitVoid")
    suspend fun Task<Void>.await() = suspendCancellableCoroutine<Unit> { continuation ->
        addOnSuccessListener { continuation.resume(Unit) }
        addOnFailureListener { continuation.resumeWithException(it) }
        addOnCanceledListener { continuation.cancel() }
    }

    suspend fun <TResult> Task<TResult>.await() = suspendCancellableCoroutine<TResult> { continuation ->
        addOnSuccessListener { continuation.resume(it) }
        addOnFailureListener { continuation.resumeWithException(it) }
        addOnCanceledListener { continuation.cancel() }
    }

}