import QtQuick 2.2
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4

import "CloudAPI.js" as CloudAPI

Item {
    id: loginView
    anchors.fill: parent
    width: 440
    height: 540

    signal loginPressed(string login, string passwd)

    Image {
        anchors.fill: parent
        source: "res/background_login.gif"
    }

    TextField {
        id: loginField
        x: 65
        y: 256
        width: 310
        height: 31
        font.pixelSize: 18
        style: TextFieldStyle {
            textColor: "black"
            background: Rectangle {
                color: "white"
            }
        }

        Keys.onPressed: if (event.key === Qt.Key_Return) { loginBtn.clicked(); event.accepted = true; }
    }

    TextField {
        id: passwdField
        x: 65
        y: 319
        width: 310
        height: 30
        font.pixelSize: 18
        echoMode: TextInput.Password
        style: TextFieldStyle {
            textColor: "black"
            background: Rectangle {
                color: "white"
            }
        }

        Keys.onPressed: if (event.key === Qt.Key_Return) { loginBtn.clicked(); event.accepted = true; }
    }

    Button {
        id: cancelBtn
      //  width: 119
      //  height: 43
        x: 91
        y: 415

        style: ButtonStyle {
            background: Image {
                source: "res/cancel_btn.gif"
            }
        }

        onClicked: pluginRootWindow.close()
    }

    Button {
        id: loginBtn
    //    width: 119
    //    height: 43
        x: 211
        y: 415
        style: ButtonStyle {
            background: Image {
                source: "res/login.gif"
            }
        }

        onClicked: {
            pluginUtils.qmlLog("login")
            if (loginField.text !== "" && passwdField.text !== "") {
                pluginRootWindow.showBusy()
                CloudAPI.login(loginField.text, passwdField.text, function(data) {
                    if (data["result"] === true) {
                        pluginRootWindow.saveSession(data["message"]["session"])
                    } else {
                        pluginRootWindow.showMessage("Error: " + data["message"])
                    }
                    pluginRootWindow.hideBusy()
                })
            }
        }
    }

    Text {
        id: regUrl
        x: 134
        y: 457
        width: 172
        height: 42
        text: '<html><style type="text/css"></style><a href="https://cloud.3dprinteros.com">Don’t have account yet? Press here to register</a></html>'
        linkColor: regUrl.hoveredLink ? "red" : "grey"
        onLinkActivated: Qt.openUrlExternally(link)
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        font.pixelSize: 13
    }
}
