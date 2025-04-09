package com.roxcard.app

import android.app.PendingIntent
import android.content.ComponentName
import android.content.Intent
import android.nfc.NfcAdapter
import android.nfc.cardemulation.CardEmulation
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.roxcard.app/nfc"
    private var nfcAdapter: NfcAdapter? = null
    private var cardEmulationManager: CardEmulation? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isNfcAvailable" -> {
                    result.success(isNfcAvailable())
                }
                "startCardEmulation" -> {
                    try {
                        val cardData = call.argument<Map<String, Any>>("cardData")
                        val success = startCardEmulation(cardData)
                        result.success(success)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error starting card emulation", e)
                        result.error("ERROR", "Failed to start card emulation", e.message)
                    }
                }
                "stopCardEmulation" -> {
                    try {
                        val success = stopCardEmulation()
                        result.success(success)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error stopping card emulation", e)
                        result.error("ERROR", "Failed to stop card emulation", e.message)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun isNfcAvailable(): Boolean {
        return try {
            nfcAdapter = NfcAdapter.getDefaultAdapter(this)
            nfcAdapter != null && nfcAdapter!!.isEnabled
        } catch (e: Exception) {
            Log.e("MainActivity", "Error checking NFC availability", e)
            false
        }
    }

    private fun startCardEmulation(cardData: Map<String, Any>?): Boolean {
        if (nfcAdapter == null) {
            nfcAdapter = NfcAdapter.getDefaultAdapter(this)
        }

        if (nfcAdapter == null || !nfcAdapter!!.isEnabled) {
            return false
        }

        try {
            // Сохраняем данные карты, которые будут использованы в CardEmulationService
            val sharedPreferences = getSharedPreferences("CardEmulationPrefs", MODE_PRIVATE)
            val editor = sharedPreferences.edit()
            
            cardData?.let {
                editor.putString("cardNumber", it["cardNumber"] as? String ?: "")
                editor.putString("cardholderName", it["cardholderName"] as? String ?: "")
                editor.putString("expiryDate", it["expiryDate"] as? String ?: "")
                editor.putString("cardType", it["cardType"] as? String ?: "")
            }
            
            editor.apply()

            // Включаем службу эмуляции карт
            cardEmulationManager = CardEmulation.getInstance(nfcAdapter)
            val serviceComponent = ComponentName(this, CardEmulationService::class.java)
            
            // На Android 10+ требуется дополнительная настройка
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val intent = Intent(this, CardEmulationService::class.java)
                startForegroundService(intent)
            }
            
            // Устанавливаем наш сервис как предпочтительный для обработки платежей
            // Исправленный код - проверяем версию API и используем соответствующий метод
            val success = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // Для Android 12 (API 31) и выше используем метод только с категорией
                cardEmulationManager?.categoryAllowsForegroundPreference(CardEmulation.CATEGORY_PAYMENT) == true
            } else {
                // Для более старых версий используем метод с компонентом
                cardEmulationManager?.setPreferredService(this, serviceComponent) == true &&
                cardEmulationManager?.isDefaultServiceForCategory(serviceComponent, CardEmulation.CATEGORY_PAYMENT) == true
            }

            if (success) {
                Log.d("MainActivity", "Card emulation service started successfully")
            } else {
                Log.w("MainActivity", "Failed to set card emulation service as foreground service")
            }

            return success
        } catch (e: Exception) {
            Log.e("MainActivity", "Error starting card emulation", e)
            return false
        }
    }

    private fun stopCardEmulation(): Boolean {
        try {
            // Очищаем данные карты
            val sharedPreferences = getSharedPreferences("CardEmulationPrefs", MODE_PRIVATE)
            val editor = sharedPreferences.edit()
            editor.clear()
            editor.apply()

            // Останавливаем сервис
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val intent = Intent(this, CardEmulationService::class.java)
                stopService(intent)
            }

            Log.d("MainActivity", "Card emulation service stopped")
            return true
        } catch (e: Exception) {
            Log.e("MainActivity", "Error stopping card emulation", e)
            return false
        }
    }

    override fun onResume() {
        super.onResume()
        
        // Настраиваем интенты для NFC активности
        if (nfcAdapter != null && nfcAdapter!!.isEnabled) {
            val intent = Intent(this, javaClass).apply {
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
            val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pendingIntent = PendingIntent.getActivity(this, 0, intent, pendingIntentFlags)
            nfcAdapter?.enableForegroundDispatch(this, pendingIntent, null, null)
        }
    }

    override fun onPause() {
        super.onPause()
        
        // Отключаем диспетчеризацию NFC, когда приложение не на переднем плане
        if (nfcAdapter != null) {
            nfcAdapter?.disableForegroundDispatch(this)
        }
    }
}
