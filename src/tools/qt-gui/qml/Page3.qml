import QtQuick 2.2
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1

Item {
	id: page3

	ColumnLayout {

		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: buttonRow.top
		anchors.top: parent.top
		anchors.margins: defaultMargins

		RowLayout {
			spacing: defaultSpacing

			Text {
				id: text
				Layout.fillWidth: true
				wrapMode: Text.WordWrap
				color: activePalette.text
				text: qsTr("Please select the plugins you want to include in the backend.")
			}
			ComboBox {
				id: pluginDropdown
				Layout.fillWidth: true
				model: guiBackend.availablePlugins()
				onCurrentTextChanged: infoText.text = guiBackend.pluginInfo(pluginDropdown.currentText)
			}
			Button {
				id: addButton

				implicitWidth:  pluginDropdown.height
				implicitHeight: pluginDropdown.height

				iconSource: "icons/list-add.png"
				tooltip: qsTr("Add Plugin")

				onClicked: {
					if(!alreadyInList(pluginDropdown.currentText)){
						guiBackend.addPlugin(pluginDropdown.currentText)

						if(!error){
							includedPluginsModel.append({"pluginName" : pluginDropdown.currentText})
							buttonRow.finishButton.enabled = guiBackend.validated()
						}
					}
				}
			}
		}
		Item {
			id: spacer

			Layout.fillWidth: true
			height: 2*defaultMargins
		}
		Label {
			id: includedPluginsLabel
			text: qsTr("Included Plugins")
			anchors.top: spacer.bottom
			anchors.left: parent.left
			anchors.bottomMargin: defaultSpacing
		}
		BasicRectangle {
			id: includedPluginsRectangle

			anchors.top: includedPluginsLabel.bottom
			anchors.left: parent.left
			anchors.right: pluginInfoRectangle.left
			anchors.bottom: parent.bottom
			anchors.topMargin: defaultSpacing
			anchors.rightMargin: defaultMargins
			width: Math.ceil(wizardLoader.width*0.3)

			ScrollView {
				anchors.fill: parent
				anchors.margins: defaultSpacing

				ListView {
					id: includedBackendsView

					model: ListModel {
						id: includedPluginsModel
					}
					delegate: Row {
						Label {
							text: pluginName
						}
					}
				}
			}
		}
		Label {
			id: pluginInfoLabel
			text: qsTr("Plugin Info")
			anchors.top: spacer.bottom
			anchors.left: pluginInfoRectangle.left
		}
		BasicRectangle {
			id: pluginInfoRectangle

			anchors.top: pluginInfoLabel.bottom
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			anchors.topMargin: defaultSpacing
			anchors.leftMargin: defaultMargins
			implicitWidth: Math.ceil(wizardLoader.width*0.7)

			TextArea {
				id: infoText

				anchors.fill: parent
				anchors.margins: 1
				textFormat: Text.RichText
				backgroundVisible: false
				frameVisible: false
				readOnly: true
				wrapMode: Text.WordWrap
			}
		}
	}
	ButtonRow {
		id: buttonRow

		finishButton.onClicked: {
			guiBackend.serialise()

			if(!error){
				wizardLoader.close()
				externTreeModel.populateModel()
				guiBackend.deleteBackend()
				includedPluginsModel.clear()
				loader.source = "Page1.qml"
			}
		}
		nextButton.visible: false
		cancelButton.onClicked: {
			wizardLoader.close()
			guiBackend.deleteBackend()
			includedPluginsModel.clear()
			loader.source = "Page1.qml"
		}
	}

	function alreadyInList(plugin) {

		for(var i = 0; i < includedPluginsModel.count; i++){
			if(includedPluginsModel.get(i).pluginName === plugin)
				return true
		}
		return false
	}

}
