//
//  StringExtension.swift
//  Oculo
//
//  Created by 최윤석 on 2022/11/10.
//  Copyright © 2022 Intelligent ATLAS. All rights reserved.
//

import Foundation

// 출처: https://medium.com/@PhiJay/why-swift-enums-with-associated-values-cannot-have-a-raw-value-21e41d5ec11

protocol Localizable: Identifiable, CaseIterable, RawRepresentable where RawValue: StringProtocol {}

extension Localizable {
    
    var localized: String {
        NSLocalizedString(String(rawValue), comment: "")
    }
    
    var id: String {
        String(self.rawValue)
    }
}

enum Language: String, Localizable {
    // Main View
    case navigation = "Navigation"
    case environmentReader = "Environment Reader"
    case textReader = "Text Reader"
    case settings = "Settings"

    // Settings View
    case membership = "Membership"
    case agreement =  "Agreement on sending recorded video"
    case arrangement = "Terms of arrangement"
    case privacy = "Privacy"
    case license = "License"
    case contactUS = "Contact Us"
    
    // Contorller
    case doorRecognition = "Reset door recognition"
    case textRecognition = "Text recognition"
}

let localizingDictionaryEngKor: [String: String] = [
    "person": "사람이",
    "bicycle": "자전거가",
    "car": "자동차가",
    "motorcycle": "오토바이가",
    "airplane": "비행기가",
    "bus": "버스가",
    "train": "기차가",
    "truck": "트럭이",
    "boat": "보트가",
    "traffic light": "신호등이",
    "fire hydrant": "소화전이",
    "stop sign": "정지 표지판이",
    "parking meter": "주차요금 정산기가",
    "bench": "벤치가",
    "bird": "새가",
    "cat": "고양이가",
    "dog": "개가",
    "horse": "말이",
    "sheep": "양이",
    "cow": "소가",
    "elephant": "코끼리가",
    "bear": "곰이",
    "zebra": "얼룩말이",
    "giraffe": "기린이",
    "backpack": "배낭이",
    "umbrella": "우산이",
    "handbag": "핸드백이",
    "tie": "넥타이가",
    "suitcase": "여행 가방이",
    "frisbee": "프리스비가",
    "skis": "스키가",
    "snowboard": "스노우보드가",
    "sports ball": "공이",
    "kite": "연이",
    "baseball bat": "야구배트가",
    "baseball glove": "야구글러브가",
    "skateboard": "스케이트보드가",
    "surfboard": "서핑보드가",
    "tennis racket": "테니스 라켓이",
    "bottle": "병이",
    "wine glass": "와인잔이",
    "cup": "컵이",
    "fork": "포크가",
    "knife": "나이프가",
    "spoon": "숟가릭이",
    "bowl": "그릇이",
    "banana": "바나나가",
    "apple": "사과가",
    "sandwich": "샌드위치가",
    "orange": "오렌지가",
    "broccoli": "브로콜리가",
    "carrot": "당근이",
    "hot dog": "핫도그가",
    "pizza": "피자가",
    "donut": "도넛이",
    "cake": "케이크가",
    "chair": "의자가",
    "couch": "소파가",
    "potted plant": "분재가",
    "bed": "침대가",
    "dining table": "식탁이",
    "toilet": "화장실이",
    "tv": "텔레비전이",
    "laptop": "노트북이",
    "mouse": "마우스가",
    "remote": "리모컨이",
    "keyboard": "키보드가",
    "cell phone": "휴대폰이",
    "microwave": "전자레인지가",
    "oven": "오븐이",
    "toaster": "토스터기가",
    "sink": "싱크대가",
    "refrigerator": "냉장고가",
    "book": "책이",
    "clock": "시계가",
    "vase": "꽃병이",
    "scissors": "가위가",
    "teddy bear": "테디베어가",
    "hair drier": "헤어 드라이기가",
    "toothbrush": "칫솔이",

]

let localizingDictionaryKorEng: [String: String] = [

    /// EnvironmentReaderViewController
    "근처에 문이 있습니다": "A door is nearby",
    "문으로부터 약 한 걸음 떨어져 있습니다": "A door is about a step away",
    "문으로부터 약 두 걸음 떨어져 있습니다": "A door is about two steps away",
    "문으로부터 약 세 걸음 떨어져 있습니다": "A door is about three steps away",
    "문으로부터 약 네 걸음 떨어져 있습니다": "A door is about four steps away",
    "문으로부터 약 다섯 걸음 떨어져 있습니다": "A door is about five steps away",
    "문으로부터 약 여섯 걸음 떨어져 있습니다": "A door is about six steps away",
    "문으로부터 약 일곱 걸음 떨어져 있습니다": "A door is about seven steps away",
    "문으로부터 약 여덟 걸음 떨어져 있습니다": "A door is about eight steps away",
    "문으로부터 약 아홉 걸음 떨어져 있습니다": "A door is about nine steps away",
    "문으로부터 멀리 떨어져 있습니다. 화면을 눌러 인식을 초기화 해주세요": "A door is far away. Please tap the screen to reset the recognition",
    "스마트폰을 좌우, 위아래로 천천히 움직여주세요.": "Please move your smartphone slowly to the left and right, up and down.",
    "환경 인식 기능에 문제가 발생했습니다.": "A problem occurred in the environment recognition.",
    "디바이스를 천천히 움직여주세요.": "Please move the device slowly.",
    "환경 인식을 할 수 없습니다.": "Cannot recognize the environment.",
    "환경 인식 기능을 초기화 중입니다.": "Now resetting the environment recognition.",
    "문 인식 초기화": "Door recognition reset",
    "문이 오른쪽에 있습니다.": "The door is on your right.",
    "문이 왼쪽에 있습니다.": "The door is on your left.",

    /// TextReaderViewController
    "글자가 인식되지 않았습니다." : "Cannot read the text.",

    /// StepString
    "에 ": " is nearby ",
    " 약 한 걸음 거리에 ": " is about a step away,",
    " 약 두 걸음 거리에 ": " is about two steps away,",
    " 약 세 걸음 거리에 ": " is about three steps away,",
    " 약 네 걸음 거리에 ": " is about four steps away,",
    " 약 다섯 걸음 거리에 ": " is about five steps away,",
    " 약 여섯 걸음 거리에 ": " is about six steps away,",
    " 약 일곱 걸음 거리에 ": " is about seven steps away,",
    " 약 여덟 걸음 거리에 ": " is about eight steps away,",
    " 약 아홉 걸음 거리에 ": " is about nine steps away,",
    " 멀리 떨어진 곳에 ": " is far away,",

    /// CoordinateString
    "우측": "right",
    "정면": "front",
    "좌측": "left",
    " 상단": " top",
    " 가운데": " center",
    " 하단": " bottom",
]

let labelsIndefiniteArticleDictionary: [String:String] = [
    "person": "A person",
    "bicycle": "A bicycle",
    "car": "A car",
    "motorcycle": "A motorcycle",
    "airplane": "An airplane",
    "bus": "A bus",
    "train": "A train",
    "truck": "A truck",
    "boat": "A boat",
    "traffic light": "A traffic light",
    "fire hydrant": "A fire hydrant",
    "stop sign": "A stop sign",
    "parking meter": "A parking meter",
    "bench": "A bench",
    "bird": "A bird",
    "cat": "A cat",
    "dog": "A dog",
    "horse": "A horse",
    "sheep": "A sheep",
    "cow": "A cow",
    "elephant": "An elephant",
    "bear": "A bear",
    "zebra": "A zebra",
    "giraffe": "A giraffe",
    "backpack": "A backpack",
    "umbrella": "An umbrella",
    "handbag": "A handbag",
    "tie": "A tie",
    "suitcase": "A suitcase",
    "frisbee": "A frisbee",
    "snowboard": "A snowboard",
    "sports ball": "A sports ball",
    "kite": "A kite",
    "baseball bat": "A baseball bat",
    "baseball glove": "A baseball glove",
    "skateboard": "A skateboard",
    "surfboard": "A surfboard",
    "tennis racket": "A tennis racket",
    "bottle": "A bottle",
    "wine glass": "A wine glass",
    "cup": "A cup",
    "fork": "A fork",
    "knife": "An knife",
    "spoon": "A spoon",
    "bowl": "A bowl",
    "banana": "A banana",
    "apple": "An apple",
    "sandwich": "A sandwich",
    "orange": "An orange",
    "broccoli": "A broccoli",
    "carrot": "A carrot",
    "hot dog": "A hot dog",
    "pizza": "A pizza",
    "donut": "A donut",
    "cake": "A cake",
    "chair": "A chair",
    "couch": "A couch",
    "potted plant": "A potted plant",
    "bed": "A bed",
    "dining table": "A dining table",
    "toilet": "A toilet",
    "tv": "A tv",
    "laptop": "A laptop",
    "mouse": "A mouse",
    "remote": "A remote",
    "keyboard": "A keyboard",
    "cell phone": "A cell phone",
    "microwave": "A microwave",
    "oven": "An oven",
    "toaster": "A toaster",
    "sink": "A sink",
    "refrigerator": "A refrigerator",
    "book": "A book",
    "clock": "A clock",
    "vase": "A vase",
    "scissors": "A scissors",
    "teddy bear": "A teddy bear",
    "hair drier": "A hair drier",
    "toothbrush": "A toothbrush",
]

func translate(_ word: String) -> String {
    if languageSetting == "ko" {
        if let korean = localizingDictionaryEngKor[word] {
            return korean
        } else {
            return word
        }
    } else {
        if let english = localizingDictionaryKorEng[word] {
            return english
        } else {
            return addlabelsIndefiniteArticle(word)
        }
    }
}

func addlabelsIndefiniteArticle(_ none: String) -> String {
    if let noneWithIndefinteArticle = labelsIndefiniteArticleDictionary[none] {
        return noneWithIndefinteArticle
    } else {
        return none
    }
}
