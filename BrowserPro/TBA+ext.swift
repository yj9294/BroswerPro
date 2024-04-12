//
//  TBA+ext.swift
//  BrowserPro
//
//  Created by Super on 2024/4/10.
//

import Foundation
import GADUtil
import TBAUtil

class EventRequest: TBARequest {
    static func preloadPool() {
        ReachabilityUtil.shared.startMonitoring()
        TBACacheUtil.isDebug = false
        Request.url = AppUtil.isDebug ? "https://test-cohesive.browserproapp.com/velvety/fran/ebb" : "https://cohesive.browserproapp.com/onto/dyestuff"
        // 国家枚举映射字段名称
        Request.osString = "billie"
        // 是否限制追踪 枚举映射字段名称
        Request.att = [true: "seaborg", false: "zinnia"]
        // sex key name
        Request.secKeyNames = ["whinny", "caption", "castro", "algal", "venturi", "showdown"]
        // min sec key name
        Request.milKeyNames = ["bizarre"]
        // id key name
        Request.idKeyNames = ["ear", "asteroid"]
        // cloak.url
        Request.cloakUrl = "https://woodside.browserproapp.com/conduce/hive/citizen"
        // cloak go key name
        Request.cloakGoName = "clarity"
        // cloak param
        var cloakParams: [String: Any] = [:]
        cloakParams["seahorse"] = Request.parametersPool()["distinct_id"]
        cloakParams["bizarre"] = Request.parametersPool()["client_ts"]
        cloakParams["conceal"] = Request.parametersPool()["device_model"]
        cloakParams["middle"] = Request.parametersPool()["bundle_id"]
        cloakParams["reck"] = Request.parametersPool()["os_version"]
        cloakParams["earl"] = Request.parametersPool()["idfv"]
        cloakParams["grotto"] = ""
        cloakParams["pimple"] = ""
        cloakParams["matrices"] = Request.parametersPool()["os"]
        cloakParams["rouge"] =  Request.parametersPool()["idfa"]
        cloakParams["gam"] = Request.parametersPool()["app_version"]
        Request.cloakParam = cloakParams
        
        
        // 公共参数
        var parameters: [String: Any] = [:]
        
        var ix: [String: Any] = [:]
        ix["rouge"] = Request.parametersPool()["idfa"]
        ix["ursula"] = Request.parametersPool()["channel"]
        ix["bizarre"] = Request.parametersPool()["client_ts"]
        ix["stodgy"] = Request.parametersPool()["network_type"]
        ix["siena"] = Request.parametersPool()["operator"]
        ix["farina"] = Request.parametersPool()["os_country"]
        ix["matrices"] = Request.parametersPool()["os"]
        ix["gam"] = Request.parametersPool()["app_version"]
        ix["ear"] = Request.parametersPool()["log_id"]
        ix["madcap"] = Request.parametersPool()["manufacturer"]
        parameters["ix"] = ix
        
        var payday:  [String: Any] = [:]
        payday["reck"] = Request.parametersPool()["os_version"]
        payday["middle"] = Request.parametersPool()["bundle_id"]
        payday["seahorse"] = Request.parametersPool()["distinct_id"]
        payday["asteroid"] = ""
        payday["naacp"] = Request.parametersPool()["system_language"]
        payday["edwina"] = Request.parametersPool()["zone_offset"]
        payday["ideal"] = Request.parametersPool()["brand"]
        payday["conceal"] = Request.parametersPool()["device_model"]
        payday["earl"] =  Request.parametersPool()["idfv"]
        parameters["payday"] = payday
        
// MARK: 全局属性
        parameters["boyar"] = ["pro_borth": Locale.current.regionCode ?? ""]
        Request.commonParam = parameters
        
        var commonHeader: [String: String] = [:]
        commonHeader["farina"] = "\(Request.parametersPool()["os_country"] ?? "")"
        commonHeader["gam"] = "\(Request.parametersPool()["app_version"] ?? "")"
        commonHeader["middle"] = "\(Request.parametersPool()["bundle_id"] ?? "")"
        Request.commonHeader = commonHeader
        
        var commonQuery: [String: String] = [:]
        commonQuery["naacp"] = "\(Request.parametersPool()["system_language"] ?? "")"
        commonQuery["edwina"] = "\(Request.parametersPool()["zone_offset"] ?? "")"
        commonQuery["seahorse"] = "\(Request.parametersPool()["distinct_id"] ?? "")"
        Request.commonQuery = commonQuery
        
        var installParam: [String: Any] = [:]
        installParam["torso"] = Request.parametersPool()["build"]
        installParam["reginald"] = Request.parametersPool()["user_agent"]
        installParam["indirect"] = Request.parametersPool()["lat"]
        installParam["whinny"] = Request.parametersPool()["referrer_click_timestamp_seconds"]
        installParam["caption"] = Request.parametersPool()["install_begin_timestamp_seconds"]
        installParam["castro"] = Request.parametersPool()["referrer_click_timestamp_server_seconds"]
        installParam["algal"] = Request.parametersPool()["install_begin_timestamp_server_seconds"]
        installParam["venturi"] = Request.parametersPool()["install_first_seconds"]
        installParam["showdown"] = Request.parametersPool()["last_update_seconds"]
        
        Request.installParam = ["doll": installParam]
        
        var sessionParam: [String: Any] = [:]
        Request.sessionParam = ["jolla": sessionParam]
        
        Request.firstOpenParam = ["rooky": "first_open"]
    
    }
    
    static func tbaADRequest(ad: GADBaseModel?) {
        var adParam: [String: Any] = [:]
        adParam["yap"] = Request.parametersPool(ad)["ad_pre_ecpm"]
        adParam["flame"] = Request.parametersPool(ad)["currency"]
        adParam["bind"] = Request.parametersPool(ad)["ad_network"]
        adParam["assist"] = Request.parametersPool(ad)["ad_source"]
        adParam["prig"] = Request.parametersPool(ad)["ad_code_id"]
        adParam["akron"] = Request.parametersPool(ad)["ad_pos_id"]
        adParam["column"] = Request.parametersPool(ad)["ad_sense"]
        adParam["madstone"] = Request.parametersPool(ad)["ad_format"]
        adParam["lysenko"] = Request.parametersPool(ad)["precision_type"]
        adParam["dour"] = Request.parametersPool(ad)["ad_load_ip"]
        adParam["aquinas"] = Request.parametersPool(ad)["ad_impression_ip"]
        Request.adParam = ["regret": adParam]
        Request.tbaRequest(key: .ad, ad: ad)
    }
    
    static func tbaEventReequest(eventKey: String = "", value: [String: Any]? = nil) {
        var eventParam: [String: Any] = [:]
        eventParam["rooky"] = eventKey
//MARK: 私有属性
        value?.keys.forEach({ key in
            eventParam[key + "^curry"] = value?[key]
        })
        Request.eventParam = eventParam
        Request.tbaRequest(key: .normalEvent, eventKey: eventKey, value: value)
    }
    static func installRequest() {
        Request.tbaRequest(key: .install)
    }
    
    static func sessionRequest() {
        Request.tbaRequest(key: .session)
    }
    
    static func firstOpenRequest() {
        Request.tbaRequest(key: .firstOpen)
    }
    
    static func cloakRequest() {
        Request.requestCloak()
    }
    
    static func eventRequest(_ event: Event, value: [String: Any] = [:]) {
        self.tbaEventReequest(eventKey: event.rawValue, value: value)
    }
 
    enum Event: String {
        case vpnHome = "pro_1"
        case vpnBack = "pro_homeback"
        case vpnConnect = "pro_link"
        case vpnConnectError = "pro_link1"
        // rot （服务器的 ip）：ip 地址
        case vpnConnectSuccess = "pro_link2"
        // rot （服务器的 ip）：ip 地址
        case vpnDidConnect = "pro_link0"
        
        case vpnPermission = "pro_pm"
        case vpnPermission1 = "pro_pm2"
        
        case vpnResultConnect = "pro_re1"
        case vpnResultDisconnect = "pro_re2"
        
        case vpnResultConnceBack = "pro_re1_back"
        case vpnResultDisconnectBack = "pro_re2_back"
        
        // duration
        case vpnDisconnectManual = "pro_disLink"
        
        case vpnGuide = "pro_pop"
        case vpnGuideSkip = "pro_pop0"
        case vpnGuideOk = "pro_pop1"
    }
}
