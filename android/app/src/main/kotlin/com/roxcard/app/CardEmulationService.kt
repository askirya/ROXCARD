package com.roxcard.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.nfc.cardemulation.HostApduService
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.core.app.NotificationCompat

class CardEmulationService : HostApduService() {
    
    companion object {
        private const val TAG = "CardEmulationService"
        
        // APDUs for our simple payment system
        private val SELECT_AID_COMMAND = byteArrayOf(
            0x00.toByte(), 0xA4.toByte(), 0x04.toByte(), 0x00.toByte(), 0x07.toByte(),
            0xF0.toByte(), 0x01.toByte(), 0x02.toByte(), 0x03.toByte(), 0x04.toByte(), 0x05.toByte(), 0x06.toByte()
        )
        
        // Success response for SELECT AID
        private val SELECT_AID_RESPONSE = byteArrayOf(
            0x90.toByte(), 0x00.toByte()
        )
        
        // Command not supported response
        private val COMMAND_NOT_SUPPORTED_RESPONSE = byteArrayOf(
            0x6A.toByte(), 0x81.toByte()
        )
        
        // READ RECORD command prefix
        private val READ_RECORD_PREFIX = byteArrayOf(
            0x00.toByte(), 0xB2.toByte()
        )
        
        // GET DATA command prefix
        private val GET_DATA_PREFIX = byteArrayOf(
            0x80.toByte(), 0xCA.toByte()
        )
        
        // VERIFY PIN prefix
        private val VERIFY_PIN_PREFIX = byteArrayOf(
            0x00.toByte(), 0x20.toByte(), 0x00.toByte(), 0x80.toByte()
        )
        
        // Notification
        private const val NOTIFICATION_CHANNEL_ID = "roxcard_channel"
        private const val NOTIFICATION_ID = 1
    }
    
    private var cardNumber: String = ""
    private var cardholderName: String = ""
    private var expiryDate: String = ""
    private var cardType: String = ""

    override fun onCreate() {
        super.onCreate()
        
        // Создаем канал уведомлений для Foreground Service (только для Android 8+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "ROXCARD Card Emulation",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notification for card emulation service"
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
        
        startForeground()
        
        // Загружаем данные карты
        loadCardData()
    }

    private fun loadCardData() {
        val prefs = getSharedPreferences("CardEmulationPrefs", Service.MODE_PRIVATE)
        cardNumber = prefs.getString("cardNumber", "") ?: ""
        cardholderName = prefs.getString("cardholderName", "") ?: ""
        expiryDate = prefs.getString("expiryDate", "") ?: ""
        cardType = prefs.getString("cardType", "") ?: ""
        
        Log.d(TAG, "Loaded card data: $cardType card for $cardholderName")
    }

    override fun processCommandApdu(commandApdu: ByteArray, extras: Bundle?): ByteArray {
        Log.d(TAG, "Received APDU command: ${bytesToHex(commandApdu)}")
        
        // Проверяем, является ли это SELECT AID
        if (isSelectAidCommand(commandApdu)) {
            Log.d(TAG, "Responding to SELECT AID command")
            return SELECT_AID_RESPONSE
        }
        
        // Проверяем, является ли это READ RECORD
        if (isReadRecordCommand(commandApdu)) {
            Log.d(TAG, "Responding to READ RECORD command")
            return createCardDataResponse()
        }
        
        // Проверяем, является ли это GET DATA
        if (isGetDataCommand(commandApdu)) {
            Log.d(TAG, "Responding to GET DATA command")
            return createCardDataResponse()
        }
        
        // Если это VERIFY PIN, всегда возвращаем успех
        if (isVerifyPinCommand(commandApdu)) {
            Log.d(TAG, "Responding to VERIFY PIN command - Always returning success")
            return SELECT_AID_RESPONSE
        }
        
        // По умолчанию отвечаем, что команда не поддерживается
        Log.d(TAG, "Command not supported")
        return COMMAND_NOT_SUPPORTED_RESPONSE
    }
    
    override fun onDeactivated(reason: Int) {
        val reasonStr = when (reason) {
            DEACTIVATION_LINK_LOSS -> "Link Loss"
            DEACTIVATION_DESELECTED -> "Deselected"
            else -> "Unknown: $reason"
        }
        Log.d(TAG, "Deactivated: $reasonStr")
    }
    
    private fun isSelectAidCommand(command: ByteArray): Boolean {
        if (command.size < SELECT_AID_COMMAND.size) return false
        
        for (i in 0 until 5) { // Проверяем только заголовок (CLA, INS, P1, P2, Lc)
            if (command[i] != SELECT_AID_COMMAND[i]) return false
        }
        
        return true
    }
    
    private fun isReadRecordCommand(command: ByteArray): Boolean {
        if (command.size < READ_RECORD_PREFIX.size) return false
        
        for (i in READ_RECORD_PREFIX.indices) {
            if (command[i] != READ_RECORD_PREFIX[i]) return false
        }
        
        return true
    }
    
    private fun isGetDataCommand(command: ByteArray): Boolean {
        if (command.size < GET_DATA_PREFIX.size) return false
        
        for (i in GET_DATA_PREFIX.indices) {
            if (command[i] != GET_DATA_PREFIX[i]) return false
        }
        
        return true
    }
    
    private fun isVerifyPinCommand(command: ByteArray): Boolean {
        if (command.size < VERIFY_PIN_PREFIX.size) return false
        
        for (i in VERIFY_PIN_PREFIX.indices) {
            if (command[i] != VERIFY_PIN_PREFIX[i]) return false
        }
        
        return true
    }
    
    private fun createCardDataResponse(): ByteArray {
        // Создаем ответ с данными карты в формате TLV (Tag-Length-Value)
        val tlvData = generateTlvData()
        
        // Добавляем статус успешного выполнения (90 00)
        val response = ByteArray(tlvData.size + 2)
        System.arraycopy(tlvData, 0, response, 0, tlvData.size)
        response[tlvData.size] = 0x90.toByte()
        response[tlvData.size + 1] = 0x00.toByte()
        
        return response
    }
    
    private fun generateTlvData(): ByteArray {
        // Преобразуем номер карты в байты
        val cardNumberBytes = cardNumber.replace(" ", "").toByteArray()
        
        // Преобразуем имя держателя карты в байты
        val cardholderNameBytes = cardholderName.toByteArray()
        
        // Преобразуем дату истечения (MM/YY -> YYMM)
        val expParts = expiryDate.split("/")
        val month = expParts.getOrNull(0) ?: "01"
        val year = expParts.getOrNull(1) ?: "99"
        val expiryBytes = (year + month).toByteArray()
        
        // Вычисляем общий размер TLV данных
        val totalSize = 2 + cardNumberBytes.size + 2 + cardholderNameBytes.size + 2 + expiryBytes.size
        
        // Создаем буфер для TLV данных
        val buffer = ByteArray(totalSize)
        var offset = 0
        
        // Добавляем номер карты (тег 5A)
        buffer[offset++] = 0x5A.toByte()
        buffer[offset++] = cardNumberBytes.size.toByte()
        System.arraycopy(cardNumberBytes, 0, buffer, offset, cardNumberBytes.size)
        offset += cardNumberBytes.size
        
        // Добавляем имя держателя карты (тег 5F20)
        buffer[offset++] = 0x5F.toByte()
        buffer[offset++] = 0x20.toByte()
        buffer[offset++] = cardholderNameBytes.size.toByte()
        System.arraycopy(cardholderNameBytes, 0, buffer, offset, cardholderNameBytes.size)
        offset += cardholderNameBytes.size
        
        // Добавляем дату истечения (тег 5F24)
        buffer[offset++] = 0x5F.toByte()
        buffer[offset++] = 0x24.toByte()
        buffer[offset++] = expiryBytes.size.toByte()
        System.arraycopy(expiryBytes, 0, buffer, offset, expiryBytes.size)
        
        return buffer
    }
    
    private fun bytesToHex(bytes: ByteArray): String {
        val result = StringBuilder()
        for (b in bytes) {
            result.append(String.format("%02X ", b))
        }
        return result.toString()
    }
    
    private fun startForeground() {
        // Создаем интент для открытия приложения
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE)
        } else {
            PendingIntent.getActivity(this, 0, intent, 0)
        }
        
        // Создаем уведомление
        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("ROXCARD активна")
            .setContentText("Эмуляция карты активна")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
        
        // Запускаем сервис в режиме переднего плана
        startForeground(NOTIFICATION_ID, notification)
    }
} 