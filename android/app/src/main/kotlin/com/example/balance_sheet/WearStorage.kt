package com.benjaminudoh10.balanced

import android.content.Context
import android.content.SharedPreferences

object WearStorage {
    private const val PREFS_NAME = "balanced_wear_prefs"
    private const val KEY_BALANCE = "balance"
    private const val KEY_INVESTMENTS = "investments"
    private const val KEY_NET_WORTH = "net_worth"
    private const val KEY_CURRENCY = "currency"

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    fun saveData(context: Context, balance: String, investments: String, netWorth: String, currency: String) {
        getPrefs(context).edit().apply {
            putString(KEY_BALANCE, balance)
            putString(KEY_INVESTMENTS, investments)
            putString(KEY_NET_WORTH, netWorth)
            putString(KEY_CURRENCY, currency)
            apply()
        }
    }

    fun getBalance(context: Context): String = getPrefs(context).getString(KEY_BALANCE, "0.00") ?: "0.00"
    fun getInvestments(context: Context): String = getPrefs(context).getString(KEY_INVESTMENTS, "0.00") ?: "0.00"
    fun getNetWorth(context: Context): String = getPrefs(context).getString(KEY_NET_WORTH, "0.00") ?: "0.00"
    fun getCurrency(context: Context): String = getPrefs(context).getString(KEY_CURRENCY, "$") ?: "$"
}
