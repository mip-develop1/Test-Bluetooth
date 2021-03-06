//
//  DeviceListViewController.swift
//  Sample_Bluetooth
//
//  Created by ミップ on 2018/08/24.
//  Copyright © 2018年 mips.systech. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth
import RealmSwift

class DeviceListViewController: UIViewController {
    
    //var RegisterTableView: UITableView!
    var uuids = [UUID]()
    var names = [UUID:String]()
    var peripherals = [UUID:CBPeripheral]()
    var targetPeripheral: CBPeripheral!
    var centralManager: CBCentralManager!

    // Realm
    
    
    @IBOutlet weak var RegisterTableView: UITableView!
    
    @IBOutlet weak var DetectedTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DetectedTableView.delegate = self
        DetectedTableView.dataSource = self
        
        self.uuids = []
        self.names = [:]
        self.peripherals = [:]
        centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
        
        // var debug = getConstructDeviceRealm()

        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}

extension DeviceListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let uuid = self.uuids[indexPath.row]
        self.targetPeripheral = self.peripherals[uuid]
        self.centralManager.connect(self.targetPeripheral, options: nil)
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "RVcell")
        let uuid = self.uuids[indexPath.row]
        cell.textLabel!.sizeToFit()
        cell.textLabel!.textColor = UIColor.blue
        cell.textLabel!.font = UIFont.systemFont(ofSize: 18)
        cell.textLabel!.text = self.names[uuid]
        cell.detailTextLabel!.font = UIFont.systemFont(ofSize: 12)
        cell.detailTextLabel!.text = uuid.description
        return cell
    }
}
extension DeviceListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.names.count
    }
}

extension DeviceListViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("state \(central.state)")
        switch central.state {
        case .poweredOff:
            print("Bluetooth:Off")
        case .poweredOn:
            print("Bluetooth:On")
            let serviceUUID = CBUUID(string: "0x180A")
            let scanServices:[CBUUID] = [serviceUUID]
            centralManager.scanForPeripherals(withServices: scanServices)
        case .resetting:
            print("resetting")
        case .unsupported:
            print("unsupported")
        case .unauthorized:
            print("unauthorized")
        default:
            print("unknown")
        }
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let uuid = UUID(uuid: peripheral.identifier.uuid)
        let found = self.uuids.contains(uuid)
        if found == false {
            self.uuids.append(uuid)
            let kCBAdvDataLocalName = advertisementData["kCBAdvDataLocalName"] as? String
            if let name = kCBAdvDataLocalName {
                self.names[uuid] = name.description
            } else {
                self.names[uuid] = "no name"
            }
            self.peripherals[uuid] = peripheral
            
            //print("peripheral.name \(String(describing:peripheral.name))")
            //print("RSSI \(RSSI)")
            //print("peripheral.identifier.uuidString \(peripheral.identifier.uuidString)")
            //print("advertisementData \(advertisementData)")
            //print("peripheral.identifier.description \(peripheral.identifier.description)")
        }
        DetectedTableView.reloadData()
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connect")
        let deviceSelectVC = DeviceSelectViewController()
        deviceSelectVC.setPeripheral(target: self.targetPeripheral)
        deviceSelectVC.setCentralManager(manager: self.centralManager)
        deviceSelectVC.searchService()
        deviceSelectVC.modalTransitionStyle = UIModalTransitionStyle.partialCurl
        // pushViewController での場合
        self.navigationController!.pushViewController(deviceSelectVC, animated: true)
        self.centralManager.stopScan()
    }
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let e = error {
            print("ConnectError \(e.localizedDescription)")
            return
        }
        print("not connect")
    }
}
extension DeviceListViewController: accessRealm {

    typealias ResultType = Object
    
    func getRealm() -> Realm {
        let realm = try! Realm()
        return realm
    }
    //func getAll() -> Results<ResultType>? {
    //    let realm = getRealm()
    //    return realm.objects(DeviceInfoModel.self).sorted(byKeyPath: "name")
    //}
    func add(object: ResultType){
        let realm = getRealm()
        try! realm.write {
            realm.add(object)
        }
    }
    func getByKey(key: String) -> ResultType? {
        let realm = getRealm()
        let datas = realm.objects(DeviceInfoModel.self).filter("key = '\(key)'")
        if datas.count > 0 {
            return datas[0]
        } else {
            return nil
        }
    }
    func set(data: Object) -> Bool {
        let realm = getRealm()
        do {
            try realm.write {
                realm.add(data,update:true)
            }
            return true
        } catch {
            print("\n Error")
        }
        return false
    }
    func delete(data: Object) -> Bool {
        let realm = getRealm()
        do {
            try realm.write {
                realm.delete(data)
            }
            return true
        } catch {
            print("\n Error:")
        }
        return false
    }
}
