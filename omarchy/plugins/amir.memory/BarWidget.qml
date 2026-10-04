import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "amir.memory"

  property double usedPercent: 0
  property double usedGiB: 0
  property double totalGiB: 0
  property bool memoryLoaded: false

  function refresh() {
    if (!memoryProc.running) memoryProc.running = true
  }

  function updateMemory(raw) {
    var values = {}
    var lines = raw.split("\n")
    for (var i = 0; i < lines.length; i++) {
      var match = lines[i].match(/^(MemTotal|MemAvailable):\s+(\d+)/)
      if (match) values[match[1]] = Number(match[2])
    }
    if (!values.MemTotal || values.MemAvailable === undefined) {
      memoryLoaded = false
      return
    }

    var used = values.MemTotal - values.MemAvailable
    totalGiB = values.MemTotal / 1048576
    usedGiB = used / 1048576
    usedPercent = Math.round(used * 100 / values.MemTotal)
    memoryLoaded = true
  }

  function gauge() {
    var filled = Math.round(usedPercent / 20)
    var result = ""
    for (var i = 0; i < 5; i++) result += i < filled ? "▰" : "▱"
    return result
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: memoryProc
    command: ["cat", "/proc/meminfo"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateMemory(text || "")
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) root.memoryLoaded = false
    }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.memoryLoaded ? (root.gauge() + " " + root.usedPercent + "%") : "▱▱▱▱▱ --%"
    active: root.memoryLoaded && root.usedPercent >= 75
    tooltipText: root.memoryLoaded
      ? "Memory in use: " + root.usedGiB.toFixed(1) + " / " + root.totalGiB.toFixed(1) + " GiB (" + root.usedPercent + "%)\n" + (root.usedPercent >= 90 ? "Critical memory pressure" : root.usedPercent >= 75 ? "High memory use" : "Available memory is healthy")
      : "Memory usage unavailable"
  }
}
