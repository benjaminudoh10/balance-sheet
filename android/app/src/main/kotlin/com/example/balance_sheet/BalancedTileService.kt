package com.benjaminudoh10.balanced

import androidx.wear.tiles.ColorBuilders.argb
import androidx.wear.tiles.ActionBuilders
import androidx.wear.tiles.LayoutElementBuilders
import androidx.wear.tiles.RequestBuilders
import androidx.wear.tiles.ResourceBuilders
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.TileService
import androidx.wear.tiles.TimelineBuilders
import androidx.wear.tiles.LayoutElementBuilders.*
import androidx.wear.tiles.ModifiersBuilders.*
import androidx.wear.tiles.DimensionBuilders.*
import com.google.common.util.concurrent.ListenableFuture
import com.google.common.util.concurrent.Futures

class BalancedTileService : TileService() {
    private val BACKGROUND_COLOR = argb(0xFF0D1117.toInt())
    private val MINT_COLOR = argb(0xFF3EE6B5.toInt())
    private val SECONDARY_TEXT_COLOR = argb(0xFF8B949E.toInt())
    private val WHITE_COLOR = argb(0xFFF0F6FC.toInt())

    override fun onTileRequest(requestParams: RequestBuilders.TileRequest): ListenableFuture<TileBuilders.Tile> {
        val balance = WearStorage.getBalance(this)
        val investments = WearStorage.getInvestments(this)
        val netWorth = WearStorage.getNetWorth(this)
        val currency = WearStorage.getCurrency(this)

        val tile = TileBuilders.Tile.Builder()
            .setResourcesVersion("1")
            .setTimeline(
                TimelineBuilders.Timeline.Builder()
                    .addTimelineEntry(
                        TimelineBuilders.TimelineEntry.Builder()
                            .setLayout(
                                LayoutElementBuilders.Layout.Builder()
                                    .setRoot(buildLayout(balance, investments, netWorth, currency))
                                    .build()
                            )
                            .build()
                    )
                    .build()
            )
            .build()
        return Futures.immediateFuture(tile)
    }

    override fun onResourcesRequest(requestParams: RequestBuilders.ResourcesRequest): ListenableFuture<ResourceBuilders.Resources> {
        return Futures.immediateFuture(
            ResourceBuilders.Resources.Builder()
                .setVersion("1")
                .build()
        )
    }

    private fun buildLayout(balance: String, investments: String, netWorth: String, currency: String): LayoutElement {
        return Box.Builder()
            .setModifiers(
                Modifiers.Builder()
                    .setBackground(
                        Background.Builder()
                            .setColor(BACKGROUND_COLOR)
                            .build()
                    )
                    .setClickable(
                        Clickable.Builder()
                            .setOnClick(ActionBuilders.LaunchAction.Builder().build())
                            .build()
                    )
                    .build()
            )
            .addContent(
                Column.Builder()
                    .addContent(
                        Text.Builder()
                            .setText("Net Worth")
                            .setFontStyle(
                                LayoutElementBuilders.FontStyle.Builder()
                                    .setColor(SECONDARY_TEXT_COLOR)
                                    .setSize(sp(12f))
                                    .build()
                            )
                            .build()
                    )
                    .addContent(
                        Text.Builder()
                            .setText("$currency$netWorth")
                            .setFontStyle(
                                LayoutElementBuilders.FontStyle.Builder()
                                    .setColor(MINT_COLOR)
                                    .setSize(sp(24f))
                                    .setWeight(LayoutElementBuilders.FONT_WEIGHT_BOLD)
                                    .build()
                            )
                            .build()
                    )
                    .addContent(Spacer.Builder().setHeight(dp(8f)).build())
                    .addContent(
                        Row.Builder()
                            .addContent(buildInfoItem("Balance", "$currency$balance"))
                            .build()
                    )
                    .addContent(Spacer.Builder().setHeight(dp(4f)).build())
                    .addContent(
                        Row.Builder()
                            .addContent(buildInfoItem("Investments", "$currency$investments"))
                            .build()
                    )
                    .build()
            )
            .build()
    }

    private fun buildInfoItem(label: String, value: String): LayoutElement {
        return Column.Builder()
            .setHorizontalAlignment(LayoutElementBuilders.HORIZONTAL_ALIGN_CENTER)
            .addContent(
                Text.Builder()
                    .setText(label)
                    .setFontStyle(
                        LayoutElementBuilders.FontStyle.Builder()
                            .setColor(SECONDARY_TEXT_COLOR)
                            .setSize(sp(10f))
                            .build()
                    )
                    .build()
            )
            .addContent(
                Text.Builder()
                    .setText(value)
                    .setFontStyle(
                        LayoutElementBuilders.FontStyle.Builder()
                            .setColor(WHITE_COLOR)
                            .setSize(sp(14f))
                            .build()
                    )
                    .build()
            )
            .build()
    }
}
