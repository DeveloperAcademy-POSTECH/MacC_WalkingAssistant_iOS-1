//
//  HealthkitManager.swift
//  Oculo
//
//  Created by heojaenyeong on 2022/10/13.
//  Copyright © 2022 Intelligent ATLAS. All rights reserved.
//


import Foundation
import HealthKit

//MARK: 코드 출처https://ios-dev-tech.tistory.com/12 를 바탕으로 커스터마이징했습니다.
class HealthkitManager {
    
    //MARK: 프로퍼티
    enum Period {
        case day
        case month
        case quater
        case half
        case year
    }
    
    private let healthStore = HKHealthStore()//헬스스토어 객체
    private var healthkitAuthorized:Bool = false//건강앱접근이 허가되었는지 확인하는 변수
    private var healthkitRetrieved:Bool = false//건강앱의 접근을통해 계산된 발걸음인지 확인하는 변수
    private var periodToRetrieve:Period = .year//검색할 기간을 설정해둔 변수, 기본적으로 1년으로 설정
    
    private let defalutWalkingStepLength: Int = 70//70 //한국인 평균 보폭 http://kpha.or.kr/board/view.php?p_pkid=6513&p_mid=16&p_mbs=01-06-02&p_code=&p_sdesc=&p_stype=&nowpage=&movepage=&p_soption1=
    private var walkingStepLength: Int = 70 //실제 유저의 보폭, 만약 유저의 권한을 얻지 못한다면 한국인 평균 보폭으로 처리할 예정
    
    
    private let healthkitListToRead = Set([ //헬스킷 읽기 권한을 받아올 목록
        //HKObjectType.quantityType(forIdentifier: .heartRate)!,
        //HKObjectType.quantityType(forIdentifier: .stepCount)!,
        //KSampleType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        //HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKSampleType.quantityType(forIdentifier: .walkingStepLength)!
    ])
    
    private let healthkitListToShare = Set([ //헬스킷 쓰기 권한을 받아올 목록
        //HKObjectType.quantityType(forIdentifier: .heartRate)!,
        //HKObjectType.quantityType(forIdentifier: .stepCount)!,
        //HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        //HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .walkingStepLength)!
    ])
    
    //MARK: 접근이 필요한 변수들의 getMethod
    public func getWalkingStepLength() -> Int { //stepWalkLength 의 get method
        return self.walkingStepLength
    }
    
    public func getHealthkitAuthorized() -> Bool { //authorized의 get mothod
        return self.healthkitAuthorized
    }
    
    public func getHealthkitRetrieved() -> Bool { //healthkitRetrieve의 get method
        return self.healthkitRetrieved
    }
    
    public func getPeriodToRetrieve() -> Period { //periodToRetrieve의 get method
        return self.periodToRetrieve
    }
    
    //MARK: 접근이 필요한 변수들의 setMethod
    public func setWalkingStepLength(walkingStepLength:Int){ //walkingStepLength 의 set method
        self.walkingStepLength = walkingStepLength
    }
    
    public func setWalkingStepLengthWithInputPeriod(period:Period){//periodToRetrieve 의 set method
        self.periodToRetrieve = period
        requestAuthorizationAndRetrieveWalkingStepLength()
    }
    
    //MARK: HealthKitManager의 init메서드
    init(){
        requestAuthorizationAndRetrieveWalkingStepLength()
    }
    
    //MARK: 메서드
    private func calPeriod(period : Period) -> Date { //분기 계산메서드
        let now = Date()//현재 시간
        
        switch period {
        case .day:
            return Calendar.current.date(byAdding: .hour, value: -24, to: now)! //현재시각으로부터 24시간전 시각 리턴
        case .month:
            return Calendar.current.date(byAdding: .month, value: -1, to: now)! //현재시각으로부터 1달전 시각 리턴
        case .quater:
            return Calendar.current.date(byAdding: .month, value: -3, to: now)! //현재시각으로부터 3달전 시각 리턴
        case .half:
            return Calendar.current.date(byAdding: .month, value: -6, to: now)! //현재시각으로부터 6달전 시각 리턴
        case .year:
            return Calendar.current.date(byAdding: .year, value: -1, to: now)! //현재시각으로부터 1년전 시각 리턴
        }
    }
    
    public func requestAuthorization() { //헬스킷 접근 권한 요청메서드
        self.healthStore.requestAuthorization(toShare: healthkitListToShare, read: healthkitListToRead) { (success, error) in
            if error != nil {
                self.healthkitAuthorized = false
                print(error.debugDescription)
            } else {
                if success {
                    self.healthkitAuthorized = true
                } else {
                    self.healthkitAuthorized = false
                }
            }
            
        }
        //return self.authorized
        
    }
    
    public func requestAuthorizationAndRetrieveWalkingStepLength() { //헬스킷 접근 권한 요청 및 보폭접근함수 콜 메서드
        self.healthStore.requestAuthorization(toShare: healthkitListToShare, read: healthkitListToRead) { (success, error) in
            if error != nil {
                print(error.debugDescription)
            } else {
                if success {
                    self.retrieveWalkingStepLength(period: self.periodToRetrieve) { (distance) in
                        self.walkingStepLength = Int(distance * 100)//미터단위로나와 71센치의 경우 0.71~~~로 나오기때문에 *100을해주고 소숫점 절사
                        
                    }
                } else {
                    self.walkingStepLength = self.defalutWalkingStepLength
                }
            }
            
        }
    }
    
    public func retrieveWalkingStepLength(period : Period, completion : @escaping (Double) -> Void) { //건강앱의 보폭데이터를 받아오는 메소드
        guard let walkingStepLengthType = HKSampleType.quantityType(forIdentifier: .walkingStepLength) else { return } //보폭데이터를 받아올것이라는타입 지정
        
        let now = Date() //현재시각
        let startDate = calPeriod(period: period)//시작시각
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)//현재시각으로부터 지금시각까지로 기간설정
        
        let query = HKStatisticsQuery(quantityType: walkingStepLengthType, quantitySamplePredicate: predicate, options: .discreteAverage) { (_,result,error ) in
            var strive: Double = 0
            
            guard let result = result, let everage = result.averageQuantity() else {
                print("보폭 받아오기 실패")
                return
            }
            strive = everage.doubleValue(for: HKUnit.meter())
            DispatchQueue.main.async {
                completion(strive)
            }

        }

        healthStore.execute(query)
    }
    
    
    public func calToStepCount (centimeter:Double) -> Int {//센치미터단위로 입력했을때 예상 걸음수 반환하는 메소드 ex. 500센치 거리 입력, 유저의 보폭 이 75일때 500/75 == 6.66666666667 => 6걸음이상 걸어야하니깐 안전을 위해 6걸음으로 내림해서 리턴
        return Int(floor(centimeter/Double(self.walkingStepLength)))
    }
    
    public func calToStepCount (meter:Double) -> Int {//미터단위로 입력했을때 예상 걸음수 반환하는 메소드
        return Int(floor(meter*100/Double(self.walkingStepLength)))
    }
    
    public func calToStepCount (kilometer:Double) -> Int { //킬로미터단위로 입력했을때 예상 걸음수 반환하는 메소드
        return Int(floor(kilometer*100*1000/Double(self.walkingStepLength)))
    }
    
    //MARK: 지금은 사용하지않지만 나중을 대비해 남겨놓는 코드
//    public func getStepCount(completion : @escaping (Double) -> Void ) { //걸음수 측정 함수, 쓸일은 없지만 차후를 대비해 보존
//        guard let stepQuntityType = HKSampleType.quantityType(forIdentifier: .stepCount) else { return }
//
//        let now = Date()
//        let startDate = Calendar.current.startOfDay(for: now)
//
//        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
//
//        let query = HKStatisticsQuery(quantityType: stepQuntityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_,result,error ) in
//            var countOfWalk: Double = 0
//
//            guard let result = result, let sum = result.sumQuantity() else {
//                print("걸음수 받아오기 실패")
//                return
//            }
//            countOfWalk = sum.doubleValue(for: HKUnit.count())
//
//
//            DispatchQueue.main.async {
//                completion(countOfWalk)
//            }
//
//        }
//
//        healthStore.execute(query)
//    }
}
