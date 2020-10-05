import Foundation
import CoreBluetooth
import Dispatch

class CpLPeripheral: NSObject {
    
    var peripheral: CBPeripheral
    var manager: CBCentralManager!
    
    private var characteristics: [CpLCharacteristic]!
    
    private var connected = false
    
    init(_ peripheral: CBPeripheral, queue: DispatchQueue!) {
        
        self.peripheral = peripheral
        
        super.init()
        
        self.peripheral.delegate = self
        manager = CBCentralManager(delegate: self, queue: queue)
        
        manager.connect(self.peripheral, options: nil)
    }
    
    init(_ peripheral: CBPeripheral, with characteristics: [CpLCharacteristic], queue: DispatchQueue!) {
        
        self.peripheral = peripheral
        
        super.init()
        
        self.peripheral = peripheral
        self.characteristics = characteristics
        manager = CBCentralManager(delegate: self, queue: queue)
    }
    
    func ad(characteristic: CpLCharacteristic) {
        
        self.characteristics.append(characteristic)
        
        if self.connected {
            
            var services = Set<CBUUID>()
            
            for c in characteristics {
                
                services.insert(c.serviceUUID)
            }
            self.peripheral.discoverServices(services.map() {return $0})
            
        }
    }
    
    func ad(characteristics: [CpLCharacteristic]) {
        
        self.characteristics.append(contentsOf: characteristics)
        
        if self.connected {
            
            var services = Set<CBUUID>()
            
            for c in characteristics {
                
                services.insert(c.serviceUUID)
            }
            self.peripheral.discoverServices(services.map() {return $0})
            
        }
    }
}


extension CpLPeripheral: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        if central.state == .poweredOn {
            
            self.manager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if let name = peripheral.name {
            
            if name == self.peripheral.name! {
                
                self.manager.stopScan()
                
                self.peripheral = peripheral
                self.peripheral.delegate = self
                
                self.manager.connect(self.peripheral, options: nil)
            }
        }
        
        print("found \(peripheral)")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        self.connected = true
        print("connected")
        
        if let characteristics = self.characteristics {
            
            var services = Set<CBUUID>()
            
            for c in characteristics {
                
                services.insert(c.serviceUUID)
            }
            peripheral.discoverServices(services.map() {return $0})
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
        print("Peripheral-Object is not able to connect to the given CBPeripher-Object: \(peripheral)")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        self.connected = false
    }
}

extension CpLPeripheral: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if let services = peripheral.services {
        
            if let characteristics = self.characteristics {
            
                var element: (CBService, [CBUUID]) // (Service, [Characteristics])
            
                var collection: [(CBService, [CBUUID])] = []
                
                var index = 0
            
                for c in characteristics {
               
                    if collection.count != 0 {
                        
                        for someElement in collection {
                            
                            if c.serviceUUID == someElement.0.uuid {
                                
                                collection[index].1.append(c.characteristicUUID)
                                
                                break
                            }
                            
                            index = index + 1
                        }
                        if index == collection.count {
                            
                            for service in services {
                                
                                if service.uuid == c.serviceUUID {
                                    
                                    element.0 = service
                                    element.1 = [c.characteristicUUID]
                                    
                                    collection.append(element)
                                    
                                    break
                                }
                            }
                        }
                    }
                    
                    else {
                        
                        for service in services {
                            
                            if service.uuid == c.serviceUUID {
                                
                                element.0 = service
                                element.1 = [c.characteristicUUID]
                                
                                collection.append(element)
                                
                                break
                            }
                        }
                    }
                    
                    for someElement in collection {
                        
                        peripheral.discoverCharacteristics(someElement.1, for: someElement.0)
                    }
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if let characteristics = service.characteristics {
            
            print("service \(service.uuid.uuidString) contains \(characteristics.count) characteristics")
            
            for characteristic in characteristics {
                
                for c in self.characteristics {
                    
                    if c.serviceUUID == service.uuid && c.characteristicUUID == characteristic.uuid && c.characteristic == nil {
                        
                        c.service = service
                        c.characteristic = characteristic
                        peripheral.readValue(for: characteristic)
                        print("active read order for \(characteristic.uuid.uuidString)")
                        self.peripheral.setNotifyValue(true, for: characteristic)
                    }
                }
                
//                peripheral.readValue(for: characteristic)
//                print("active read order for \(characteristic.uuid.uuidString)")
//                self.peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        for c in self.characteristics {
            
            if c.characteristic == characteristic {
                
                c.value = characteristic.value
                break
            }
        }
    }
}

class CpLCharacteristic {
    
    var value: Data! {
        
        willSet {
            
            previousValue = value
        }
        
        didSet {
            
            self.timeOfBackup = Date()
            
            if let _ = self.delegate {
                
                delegate.characteristic(self, didUpdateValue: value)
            }
            
        }
    }
    
    var previousValue: Data!
    
    var timeOfBackup: Date!
    
    let serviceUUID: CBUUID
    var service: CBService!
    let characteristicUUID: CBUUID
    var characteristic: CBCharacteristic!
    
    var delegate: CpLCharacteristicDelegate!
    
    init(_ link: CpLCharacteristicLink, delegate: CpLCharacteristicDelegate!) {
        
        serviceUUID = link.service
        characteristicUUID = link.characteristic
        
        self.delegate = delegate
    }

}

public struct CpLCharacteristicLink {
    
    public init(service: CBUUID, characteristic: CBUUID) {
        
        self.service = service
        self.characteristic = characteristic
    }
    
    public let service: CBUUID
    public let characteristic: CBUUID
}

protocol CpLCharacteristicDelegate {
    
    func characteristic(_ characteristic: CpLCharacteristic, didUpdateValue value: Data!)
}

