import Foundation
import CoreBluetooth
import CoreLocation
import Dispatch

public class CpLLocationManager {
    
    private var robot: CpLPeripheral?
    private var peripheral: CBPeripheral
    private var input: CpLCharacteristic!
    private var queue: DispatchQueue?
    
    public private(set) var locations: [CLLocationCoordinate2D] = [] {
        
        didSet {
            
            if let delegate = self.delegate {
                
                delegate.locationManager(self, didUpdateLocations: locations)
            }
        }
    }
    public var delegate: CpLLocationManagerDelegate?
    
    public init(characteristic: CpLCharacteristicLink, on peripheral: CBPeripheral, queue: DispatchQueue!, delegate: CpLLocationManagerDelegate!) {
        
        self.peripheral = peripheral
        input = CpLCharacteristic(characteristic, delegate: self)
        self.queue = queue
        self.delegate = delegate
    }
    
    public func startUpdatingLocation() {
        
        robot = CpLPeripheral(peripheral, with: [input], queue: queue)
    }
    
    private func getCoordinates(azimuts: (Double, Double), elevations: (Double, Double), time: Int, date: Int) -> CLLocationCoordinate2D {
        
        let azimut1 = (Double.pi / 180) * azimuts.0
        let azimut2 = (Double.pi / 180) * azimuts.1
        let elevation1 = (Double.pi / 180) * elevations.0
        let elevation2 = (Double.pi / 180) * elevations.1
        
        let phi = atan( -1 * tan(elevation2) * cos(azimut2 - Double.pi) - sin(azimut2 - Double.pi) * (azimut2 - azimut1) / (elevation2 - elevation1))
        
        let woz = (54000 / (15 * Double.pi)) * (atan( sin(azimut2 - Double.pi) / (cos(azimut2 - Double.pi) * sin(phi) + tan(elevation2) *  cos(phi))) + Double.pi)
        let lambda = (15 * Double.pi / 54000) * (woz - getZG(Double(date)) - Double(time))
        
        return CLLocationCoordinate2D(latitude: (180 / Double.pi) * phi, longitude: (180 / Double.pi) * lambda)
    }
}

extension CpLLocationManager: CpLCharacteristicDelegate {
    
    func characteristic(_ characteristic: CpLCharacteristic, didUpdateValue value: Data!) {
        
        guard let _ = characteristic.previousValue else{return}
        
        guard let input1 = characteristic.previousValue, let input2 = characteristic.value else{return}
        
        let string1 = String(decoding: input1, as: UTF8.self)
        var stringInput1 = ("", "")
        
        var first = true
        
        for c in string1 {
            
            if c == ";" {
                
                first = false
            }
            else if first {
                
                stringInput1.0.append(c)
            }
            else {
                
                stringInput1.1.append(c)
            }
        }
        
        first = true
        
        let string2 = String(decoding: input2, as: UTF8.self)
        var stringInput2 = ("", "")
        
        for c in string2 {
            
            if c == ";" {
                
                first = false
            }
            else if first {
                
                stringInput2.0.append(c)
            }
            else {
                
                stringInput2.1.append(c)
            }
        }
        
        if let azimut1 = Double(stringInput1.0), let elevation1 = Double(stringInput1.1) {
            
            if let azimut2 = Double(stringInput2.0), let elevation2 = Double(stringInput2.1) {
                
                print("\(azimut1) \(azimut2) \(elevation1) \(elevation2)")
                
                self.locations.append(self.getCoordinates(azimuts: (azimut1, azimut2), elevations: (elevation1, elevation2), time: characteristic.timeOfBackup.timeInSec, date: characteristic.timeOfBackup.dateInSec))
            }
        }
    }
}

public protocol CpLLocationManagerDelegate {
    
    func locationManager(_ locationManager: CpLLocationManager, didUpdateLocations locations: [CLLocationCoordinate2D])
}
