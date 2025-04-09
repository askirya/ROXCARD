package com.example.roxcard;

import android.nfc.cardemulation.HostApduService;
import android.os.Bundle;
import android.util.Log;
import java.util.Arrays;

public class CardEmulationService extends HostApduService {
    private static final String TAG = "CardEmulationService";
    
    // ISO-DEP команда для выбора приложения
    private static final byte[] SELECT_APP_COMMAND = {
            (byte) 0x00, // CLA
            (byte) 0xA4, // INS
            (byte) 0x04, // P1
            (byte) 0x00, // P2
            (byte) 0x07, // Lc (длина данных)
            (byte) 0xA0, (byte) 0x00, (byte) 0x00, (byte) 0x00, (byte) 0x04, (byte) 0x10, (byte) 0x10 // AID
    };
    
    // Ответ на успешный выбор приложения
    private static final byte[] SELECT_APP_RESPONSE = {
            (byte) 0x90, // SW1: статус без ошибок
            (byte) 0x00  // SW2: без дополнительной информации
    };
    
    // Демонстрационный ответ на другие команды
    private static final byte[] UNKNOWN_COMMAND_RESPONSE = {
            (byte) 0x6A, // SW1: статус с ошибкой
            (byte) 0x82  // SW2: файл не найден
    };
    
    @Override
    public byte[] processCommandApdu(byte[] commandApdu, Bundle extras) {
        Log.i(TAG, "Получена команда APDU: " + bytesToHexString(commandApdu));
        
        // Проверяем, соответствует ли команда выбору нашего приложения
        if (Arrays.equals(SELECT_APP_COMMAND, commandApdu)) {
            Log.i(TAG, "Обнаружена команда SELECT APPLICATION");
            return SELECT_APP_RESPONSE;
        }
        
        // Для демонстрации возвращаем фиксированный ответ на все остальные команды
        Log.i(TAG, "Получена неизвестная команда");
        return UNKNOWN_COMMAND_RESPONSE;
    }
    
    @Override
    public void onDeactivated(int reason) {
        Log.i(TAG, "Служба деактивирована, причина: " + reason);
    }
    
    // Вспомогательный метод для логирования байтов в виде шестнадцатеричной строки
    private String bytesToHexString(byte[] bytes) {
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) {
            sb.append(String.format("%02X ", b));
        }
        return sb.toString();
    }
} 