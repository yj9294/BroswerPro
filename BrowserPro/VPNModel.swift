//
//  VPNModel.swift
//  BrowserPro
//
//  Created by Super on 2024/4/9.
//

import Foundation
import UIKit
import Combine

struct VPNCountryList: Codable, Equatable, Hashable {
    var hCountries: [VPNCountry] // 高区间服务器
    var lCountries: [VPNCountry] // 低区间服务器
    var hRate: Int // 高区间概率
    var lRate: Int // 低区间概率
    
    enum CodingKeys: String, CodingKey {
        case hCountries = "human"
        case lCountries = "natural"
        case hRate = "really"
        case lRate = "professor"
    }
    
    static func requestConfig() {
        if AppUtil.shared.vpnCountryList == nil {
            let path = Bundle.main.path(forResource: "server", ofType: "json")
            let url = URL(fileURLWithPath: path!)
            do {
                let data = try Data(contentsOf: url)
                let config = try JSONDecoder().decode(VPNCountryList.self, from: data)
                AppUtil.shared.vpnCountryList = config
                AppUtil.shared.vpnCountryList?.hCountries = VPNCountryList.repeatCountry(with: config.hCountries)
                AppUtil.shared.vpnCountryList?.lCountries = VPNCountryList.repeatCountry(with: config.lCountries)
                NSLog("[Config] Read local server list config success.")
            } catch let error {
                NSLog("[Config] Read local server list config fail.\(error.localizedDescription)")
            }
        }
    }
    
    static func requestRemoteConfig() {
        
        struct DecodeMode: Codable {
            var br: String
            var rp: Int
        }
        
        let token = SubscriptionToken()
        let url = URL(string: AppUtil.shared.isDebug ? "https://test.browserproapp.com/tp/qruz/" : "https://prod.browserproapp.com/tp/qruz/")!
        if let request = try? URLRequest(url: url, method: .post, headers: ["BRO": "com.searchPro.browsers.fastApp", "SRP": AppUtil.version]) {
            NSLog("[server] 开始请求 url:\(url) method:\(request.httpMethod ?? "") header:\(request.headers)")
            URLSession.shared.dataTaskPublisher(for: request).map({
                $0.data
            }).eraseToAnyPublisher().decode(type: DecodeMode.self, decoder: JSONDecoder()).sink { complete in
                if case .failure(let error) = complete {
                    NSLog("[server] err:\(error)")
                }
                token.unseal()
            } receiveValue: { model in
                // Step 2: 去除首尾的 10 个字符、逆序、Base64 解码
                let trimmedString = String(model.br.dropFirst(10).dropLast(10))
                let reversedString = String(trimmedString.reversed())
                // Step 3: 将新字符串逆序，并进行大小写互相转换
                let reversedAndCaseFlippedString = String(reversedString).map {
                    $0.isLowercase ? $0.uppercased() : $0.lowercased()
                }.joined()
                guard let decodedData = Data(base64Encoded: reversedAndCaseFlippedString) else {
                    NSLog("[server] Failed to decode from Base64.")
                    return
                }

                // Step 3: 解码后的内容转换为 JSON 字符串
                guard let decodedString = String(data: decodedData, encoding: .utf8) else {
                    NSLog("[server] Failed to convert decoded data to string.")
                    return
                }
                
                // 4. 解密的内容得到json字符串
                if let bData = decodedString.data(using: .utf8), let model = try? JSONDecoder().decode(VPNCountryList.self, from: bData) {
                    AppUtil.shared.vpnCountryList = model
                    AppUtil.shared.vpnCountryList?.hCountries = VPNCountryList.repeatCountry(with: model.hCountries)
                    AppUtil.shared.vpnCountryList?.lCountries = VPNCountryList.repeatCountry(with: model.lCountries)
                } else {
                    NSLog("[server] error: decode json error")
                }
            }.seal(in: token)
        }
    }
    
    static let `default`: Self = VPNCountryList(hCountries: [], lCountries: [], hRate: 0, lRate: 0)
    
    func allModels() -> [VPNCountry] {
        [.smart] + hCountries + lCountries
    }
    
    func models() -> [VPNCountry] {
        NSLog("[server] 开始查找 区间 服务器集群")
        NSLog("[server] 开始随机")
        var h = hRate
        var l = lRate
        if hCountries.isEmpty, lCountries.isEmpty {
            NSLog("[server] 服务器配置错误, 无任何服务器")
            return[]
        } else if hCountries.isEmpty {
            h = 0
            l = 100
            NSLog("[server] 高区间未配置服务器, 调整低区间概率为100")
        } else if lCountries.isEmpty {
            h = 100
            l = 0
            NSLog("[server] 低区间未配置服务器, 调整高区间概率为100")
        }
        let randomKey = arc4random() % 100
        NSLog("[server] 随机值: \(randomKey) 高:\(h) 低\(l)")
        if randomKey < h {
            NSLog("[server] \(randomKey)小于高区间概率: \(h) 使用高区间服务器")
            return hCountries
        } else {
            NSLog("[server] \(randomKey)不小于高区间概率: \(h) 使用低区间服务器")
            return lCountries
        }
    }
    
    static func repeatCountry(with models: [VPNCountry]) -> [VPNCountry] {
        NSLog("[server] 开始去重 country 服务器 \(models)")
        let uniqueObjects = models.reduce(into: [String: Int]()) { uniqueObjects, object in
            if let existingValue = uniqueObjects[object.ip] {
                uniqueObjects[object.ip] = existingValue + object.weight
            } else {
                uniqueObjects[object.ip] = object.weight
            }
        }

        // 将结果转换为包含对象的数组
        let result = uniqueObjects.compactMap { obj in
            if var model: VPNCountry = models.filter({$0.ip == obj.key}).first {
                model.weight = obj.value
                return model
            }
            return nil
        }

        // 打印结果
        NSLog("[server] 去重完 country 服务器: result:\(result)")
        return result
    }
    
    static func smartModel(with models: [VPNCountry]) -> VPNCountry? {
        NSLog("[server] 开始查找 smart 服务器")
        NSLog("[server] 开始随机")
        let totalWeight: Double = Double(models.map({$0.weight}).reduce(0, +))
        let random = Double(arc4random() % 100)
        NSLog("[server] 随机数：\(Int(random))")
        var start = 0.0
        var end = 0.0
        return models.filter{ m in
            let alt = Double(m.weight) / totalWeight * 100
            end = start + alt
            if random >= start, random < end {
                NSLog("[server] 选中 ip: \(m.ip) 权重: \(m.weight), \(Int(alt))%")
                start = end
                return true
            } else {
                NSLog("[server] ip: \(m.ip) 权重: \(m.weight), \(Int(alt))%")
                start = end
                return false
            }
        }.first
    }
}


struct VPNCountry: Codable, Equatable, Hashable, Identifiable {
    let id = UUID().uuidString
    var ip: String
    var weight: Int
    var code: String
    var country: String
    var city: String
    var config: [Config]
    var delay: Double?
    struct Config: Codable, Equatable, Hashable {
        var psw: String
        var method: String
        var port: Int
        
        enum CodingKeys: String, CodingKey {
            case psw = "focus"
            case method = "sister"
            case port = "room"
        }
    }
    enum CodingKeys: String, CodingKey {
        case ip = "knowledge"
        case weight = "better"
        case code = "unit"
        case country = "network"
        case city = "learn"
        case config = "beyond"
    }
    static let smart: Self = VPNCountry(ip: "", weight: 0, code: "fastest", country: "", city: "Smart server", config: [])
    var isSmart: Bool { self == .smart }
    var title: String {
        return self.isSmart ? city : "\(country)-\(city)"
    }
    var icon: String {
        return "country_\(code)"
    }
    
    var image: String {
        if UIImage(named: icon) == nil {
            return "country_unknow"
        } else {
            return icon
        }
    }
}

class SubscriptionToken {
    var cancelable: AnyCancellable?
    func unseal() { cancelable = nil }
}

extension AnyCancellable {
    /// 需要 出现 unseal 方法释放 cancelable
    func seal(in token: SubscriptionToken) {
        token.cancelable = self
    }
}
