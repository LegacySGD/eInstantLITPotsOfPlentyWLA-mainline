<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
					<![CDATA[
					var debugFeed = [];
					var debugFlag = false;
					var bonusTotal = 0; 
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNamesDesc)
					{
						var scenario = getScenario(jsonContext);
						var scenarioMainGame = getMainGameData(scenario);
						var scenarioPOGBonusGame = getPOGBonusGameData(scenario);
						var scenarioLAHBonusGame = getLAHBonusGameData(scenario);
						var convertedPrizeValues = (prizeValues.substring(1)).split('|');
						var prizeNames = (prizeNamesDesc.substring(1)).split(',');

						////////////////////
						// Parse scenario //
						////////////////////

						var mgPrizeSymbCounts = [0,0,0,0,0,0,0,0,0];
						var mgLastMatchOfPrizeSymb = [-1,-1,-1,-1,-1,-1,-1,-1,-1];
						var mgPOGSymbCount = 0;
						var mgLAHSymbCount = 0;
						var mgLastMatchOfLAHSymb = -1;
						var mgSymb = '';
						var mgPrizeIndex = 0;
						var doWonMGPrize = false;
						var doPOGBonusGame = false;
						var doLAHBonusGame = false;

						for (var symbIndex=0; symbIndex<16; symbIndex++)
						{
							mgSymb = scenarioMainGame[symbIndex];

							if (isPrizeSymb(mgSymb))
							{
								mgPrizeIndex = getIndexOfPrizeChar(mgSymb);
								mgPrizeSymbCounts[mgPrizeIndex]++;
								mgLastMatchOfPrizeSymb[mgPrizeIndex] = symbIndex;
								doWonMGPrize = (doWonMGPrize || (!doWonMGPrize && mgPrizeSymbCounts[mgPrizeIndex] == 3));
							}
							else if (mgSymb == 'P')
							{
								mgPOGSymbCount++;
								doPOGBonusGame = true;
							}
							else if (mgSymb == 'L')
							{
								mgLAHSymbCount++;
								mgLastMatchOfLAHSymb = symbIndex;
								doLAHBonusGame = (mgLAHSymbCount == 3);
							}
						}

						///////////////////////
						// Output Game Parts //
						///////////////////////

						var r = [];
						var mgCellIndex = -1;
						var mgCellText = '';

						const gridCols 		= 4;
						const gridRows 		= 4;
						const symbPrizes    = 'ABCDEFGHILP';

						const colourAquamarine = '#7fffd4';
						const colourBlack   = '#000000';
						const colourBlue    = '#99ccff';
						const colourBrown   = '#990000';
						const colourGreen   = '#00cc00';
						const colourMidGreen= '#00ff00';
						const colourDkGrey  = '#202020';
						const colourMidGrey = '#7c7c7c';
						const colourLemon   = '#ffff99';
						const colourLilac   = '#ccccff';
						const colourLime    = '#ccff99';
						const colourDeepMag = '#b300b3';
						const colourNavy    = '#0000ff';
						const colourOrange  = '#ff7c00';
						const colourPeach   = '#ffcc99';
						const colourPink    = '#ffccff';
						const colourPurple  = '#cc99ff';
						const colourRed     = '#ff9999';
						const colourScarlet = '#ff0000';
						const colourWhite   = '#ffffff';
						const colourYellow  = '#ffff00';

						//								A			B				C			D			E			F				G				H			I			L			P				
						const prizeColours       = [colourLemon, colourPink, colourPurple, colourBlue, colourRed, colourAquamarine, colourPeach, colourLilac, colourScarlet, colourGreen, colourOrange];

						const keyCellHeight = 24;
						const keyCellWidth  = 24;
						const mgCellHeight  = 48;
						const mgCellWidth   = 48;
						const cellMargin    = 1;
						const cellSizeX     = 80;
						const cellSizeY     = 48;
						const cellTextY     = 15; 
						const cellTextY1    = 20; 

						var boxColourStr  = '';
						var textColourStr = '';
						var canvasIdStr   = '';
						var elementStr    = '';

						function showSymb(A_strCanvasId, A_strCanvasElement, A_iBoxHeight, A_iBoxWidth, A_strBoxColour, A_strTextColour, A_strText)
						{
							var canvasCtxStr = 'canvasContext' + A_strCanvasElement;
							var canvasHeight = A_iBoxHeight + 2 * cellMargin;
							var canvasWidth  = A_iBoxWidth + 2 * cellMargin;

							r.push('<canvas id="' + A_strCanvasId + '" width="' + canvasWidth.toString() + '" height="' + canvasHeight.toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.font = "bold 12px Arial";');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');
							r.push(canvasCtxStr + '.strokeRect(' + (cellMargin + 0.5).toString() + ', ' + (cellMargin + 0.5).toString() + ', ' + A_iBoxWidth.toString() + ', ' + A_iBoxHeight.toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strBoxColour + '";');
							r.push(canvasCtxStr + '.fillRect(' + (cellMargin + 1.5).toString() + ', ' + (cellMargin + 1.5).toString() + ', ' + (A_iBoxWidth -2).toString() + ', ' + (A_iBoxHeight -2).toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strTextColour + '";');
							r.push(canvasCtxStr + '.fillText("' + A_strText + '", ' + (A_iBoxWidth / 2 + cellMargin).toString() + ', ' + (A_iBoxHeight / 2 + cellMargin * 2).toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + textColourStr + '";');

							r.push('</script>');
						}

						///////////////////////////
						// Main Game Symbols Key //
						///////////////////////////
						r.push('<div style="float:left; margin-right:50px">');
						r.push('<p>' + getTranslationByName("titleSymbolsKey", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr class="tablehead">');
						r.push('<td>' + getTranslationByName("keySymbol", translations) + '</td>');
						r.push('<td>' + getTranslationByName("keyDescription", translations) + '</td>');
						r.push('</tr>');

						for (var prizeIndex = 0; prizeIndex < symbPrizes.length; prizeIndex++)
						{
							symbPrize    = symbPrizes[prizeIndex];
							canvasIdStr  = 'cvsKeySymb' + symbPrize;
							elementStr   = 'keyPrizeSymb' + symbPrize;
							boxColourStr = prizeColours[prizeIndex];
							symbDesc     = 'symb' + symbPrize;

							r.push('<tr class="tablebody">');
							r.push('<td align="center">');

							showSymb(canvasIdStr, elementStr, keyCellHeight, keyCellWidth, boxColourStr, colourBlack, symbPrize);

							r.push('</td>');
							r.push('<td>' + getTranslationByName(symbDesc, translations) + '</td>');
							r.push('</tr>');
						}

						r.push('</table>');
						r.push('</div>');


						///////////////
						// Main Game //
						///////////////
						r.push('<div style="clear:both">');
						r.push('<br>');
						r.push('<p>' + getTranslationByName("mainGameGrid", translations) + '</p>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable" style="table-layout:fixed">');

						for (var mgGridRow=0; mgGridRow<4; mgGridRow++)
						{
							r.push('<tr class="tablebody">');

							for (var mgGridCol=0; mgGridCol<4; mgGridCol++)
							{
								mgPrizeIndex = 0;
								mgCellIndex = 4 * mgGridRow + mgGridCol;
								mgSymb = scenarioMainGame[mgCellIndex];

								canvasIdStr   = 'cvsMainGame' + mgCellIndex.toString();
								elementStr    = 'eleMainGame' + mgCellIndex.toString();
								boxColourStr  = prizeColours[symbPrizes.indexOf(mgSymb)];
								textColourStr = colourBlack;

								r.push('<td>');
								showSymb(canvasIdStr, elementStr, mgCellHeight, mgCellWidth, boxColourStr, textColourStr, mgSymb);
								r.push('</td>');
							}

							r.push('</tr>');
						}
						
						r.push('</table>');

						if (doWonMGPrize)
						{
							r.push('<p>' + getTranslationByName("mainGamePrizes", translations) + '</p>');

							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable" style="table-layout:fixed">');
							r.push('<tr class="tablehead">');
							r.push('<td>' + getTranslationByName("mainGamePrizeSymb", translations) + '</td>');
							r.push('<td>' + getTranslationByName("mainGamePrizeQty", translations) + '</td>');
							r.push('<td>' + getTranslationByName("mainGamePrizeAmount", translations) + '</td>');
							r.push('</tr>');

							var mgWonPrize = '';
							var mgWonPrizeSymb = '';
							var mgWonPrizeQty = 0;

							for (var prizeIndex=0; prizeIndex<9; prizeIndex++)
							{
								mgWonPrizeQty = mgPrizeSymbCounts[prizeIndex];

								if (mgWonPrizeQty >= 3)
								{
									mgWonPrizeSymb = getPrizeCharForIndex(prizeIndex);
									mgWonPrize = mgWonPrizeSymb + (mgWonPrizeQty).toString();

									canvasIdStr   = 'cvsMainGameSummary' + prizeIndex.toString() + mgWonPrizeSymb;
									elementStr    = 'eleMainGameSummary' + prizeIndex.toString() + mgWonPrizeSymb;
									boxColourStr  = prizeColours[symbPrizes.indexOf(mgWonPrizeSymb)];
									textColourStr = colourBlack;

									r.push('<tr class="tablebody">');
									//r.push('<td>' + getTranslationByName("symb" + mgWonPrizeSymb, translations) + '</td>');
									r.push('<td>');
									showSymb(canvasIdStr, elementStr, keyCellHeight, keyCellWidth, boxColourStr, textColourStr, mgWonPrizeSymb);
									r.push('</td>');

									r.push('<td>' + mgWonPrizeQty + '</td>');
									r.push('<td>' + convertedPrizeValues[getPrizeNameIndex(prizeNames, mgWonPrize)] + '</td>');
									r.push('</tr>');
								}
							}

							r.push('</table>');
						}

						if (doPOGBonusGame)
						{
							r.push('<br>');
							r.push('<p>' + getTranslationByName("pogBonusPrizes", translations) + '</p>');

							r.push(getTranslationByName("pogBonusPrizeWon", translations) + ' ' + convertedPrizeValues[getPrizeNameIndex(prizeNames, scenarioPOGBonusGame[0])]);
						}

						if (doLAHBonusGame)
						{
							r.push('<br>');
							r.push('<p>' + getTranslationByName("lahBonusPrizes", translations) + '</p>');

							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable" style="table-layout:fixed">');
							r.push('<tr class="tablehead">');
							r.push('<td>' + getTranslationByName("lahBonusTurn", translations) + '</td>');

							for (var lahCellIndex=0; lahCellIndex<16; lahCellIndex++)
							{
								r.push('<td align="center">' + (lahCellIndex+1).toString() + '</td>');
							}

							r.push('<td>' + getTranslationByName("lahBonusCount", translations) + '</td>');
							r.push('<td>' + getTranslationByName("lahBonusPrize", translations) + '</td>');
							r.push('</tr>');

							var lahTurnCount = 0;
							var lahPrize = '';
							var lahPrizeSymb = '';

							for (var lahTurnIndex=0; lahTurnIndex<scenarioLAHBonusGame.length; lahTurnIndex++)
							{
								lahTurnCount = 0;

								r.push('<tr class="tablebody">');
								r.push('<td align="center">' + (lahTurnIndex+1).toString() + '</td>');

								for (lahTurnCellIndex=0; lahTurnCellIndex<16; lahTurnCellIndex++)
								{
									mgSymb = scenarioLAHBonusGame[lahTurnIndex][lahTurnCellIndex];
									mgCellText = getTranslationByName("symb" + mgSymb, translations);

								//	r.push('<td>' + mgCellText + '</td>');
									canvasIdStr   = 'cvsCloverBonusGame' + lahTurnIndex.toString() + '_' + lahTurnCellIndex.toString();
									elementStr    = 'eleCloverBonusGame' + lahTurnIndex.toString() + '_' + lahTurnCellIndex.toString();
									boxColourStr  = prizeColours[symbPrizes.indexOf(mgSymb)];
									textColourStr = colourBlack;

									r.push('<td>');
									showSymb(canvasIdStr, elementStr, keyCellHeight, keyCellWidth, boxColourStr, textColourStr, mgSymb);
									r.push('</td>');

									if (mgSymb == 'L')
									{
										lahTurnCount++;
									}
								}

								r.push('<td align="center">' + (lahTurnCount).toString() + '</td>');

								lahPrize = '';

								if (lahTurnIndex+1 == scenarioLAHBonusGame.length)
								{
									lahPrizeSymb = 'L' + (lahTurnCount).toString();
									lahPrize = convertedPrizeValues[getPrizeNameIndex(prizeNames, lahPrizeSymb)];
								}

								r.push('<td>' + lahPrize + '</td>');
								r.push('</tr>');
							}

							r.push('</table>');
						}

						r.push('<p>&nbsp;</p>');

						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						if(debugFlag)
						{
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
 							{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
 								r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
 								r.push('</td>');
	 							r.push('</tr>');
							}
							r.push('</table>');
						}
						return r.join('');
					}

					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeStructStrings = prizeStructures.split("|");

						for(var i = 0; i < pricePoints.length; ++i)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								return prizeStructStrings[i];
							}
						}

						return "";
					}

					// Input: Json document string containing 'scenario' at root level.
					// Output: Scenario value.
					function getScenario(jsonContext)
					{
						// Parse json and retrieve scenario string.
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						// Trim null from scenario string.
						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}

					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;

						return pricePoint;
					}

					function getMainGameData(scenario)
					{
						return scenario.split("|")[0];
					}

					function getPOGBonusGameData(scenario)
					{
						var pogBonusGameData = scenario.split("|")[1];

						return pogBonusGameData.split(",");
					}

					function getLAHBonusGameData(scenario)
					{
						var lahBonusGameData = scenario.split("|")[2];

						return lahBonusGameData.split(",");
					}

					function getIndexOfPrizeChar(prizeChar)
					{
						return prizeChar.charCodeAt(0) - 'A'.charCodeAt(0);
					}

					function getPrizeCharForIndex(prizeIndex)
					{
						return String.fromCharCode(prizeIndex + 'A'.charCodeAt(0));
					}

					function isPrizeSymb(dataChar)
					{
						return (dataChar >= 'A' && dataChar <= 'I');
					}

					// Input: "A,B,C,D,..." and "A"
					// Output: index number
					function getPrizeNameIndex(prizeNames, currPrize)
					{
						for(var i = 0; i < prizeNames.length; ++i)
						{
							if(prizeNames[i] == currPrize)
							{
								return i;
							}
						}
					}

					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}

					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
