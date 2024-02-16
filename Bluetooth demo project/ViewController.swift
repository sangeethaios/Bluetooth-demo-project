//
//  ViewController.swift
//  Bluetooth demo project
//
//  Created by Ardhas Dev on 16/02/24.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!

    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral?
    var discoveredDevices: [CBPeripheral] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        registerCell()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        tableView.delegate = self
        tableView.dataSource = self
    }
    //MARK: Register cell
    func registerCell(){
        let regcell = UINib(nibName: "DeviceCell", bundle: nil)
        tableView.register(regcell, forCellReuseIdentifier: "DeviceCell")
    
    }
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        } else {
            print("Bluetooth is not available...")
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredDevices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath) as! DeviceCell
        let device = discoveredDevices[indexPath.row]
        cell.namelbl?.text = device.name ?? "Unnamed Device"
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let device = discoveredDevices[indexPath.row]
        centralManager.stopScan()
        centralManager.connect(device, options: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredDevices.contains(peripheral) {
            discoveredDevices.append(peripheral)
            tableView.reloadData()
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "Unknown Device")")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            print("Disconnected from \(peripheral.name ?? "Unknown Device") with error: \(error.localizedDescription)")
        } else {
            print("Disconnected from \(peripheral.name ?? "Unknown Device")")
        }
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.properties.contains(.read) {
                    peripheral.readValue(for: characteristic)
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            let valueString = String(data: data, encoding: .utf8) ?? "Data could not be converted to String"
            print("Received value: \(valueString)")
        }
    }
}

