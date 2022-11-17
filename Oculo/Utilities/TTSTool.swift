//
//  TTSTool.swift
//  Oculo
//
//  Created by Dongjin Jeon on 2022/11/11.
//  Copyright © 2022 Intelligent ATLAS. All rights reserved.
//

import AVFoundation
import UIKit

public class TTSTool {
    /// TTS 기능의 소리 제어
    let synthesizer = AVSpeechSynthesizer()
    
    var speakingRate = AVSpeechUtteranceDefaultSpeechRate
    var speakingVolume = Float(1.0)

    /// String을 입력 받아 TTS 수행
    func speak(_ string: String) {
        // VoiceOver와 충돌을 방지하기 위해 VoiceOver가 문장을 읽어 주는 것으로 변경하였습니다.
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .announcement, argument: string)
        } else {
            // VoiceOver를 사용하지 않는 경우, TTS가 문장을 읽음.
            let utterance = AVSpeechUtterance(string: string)
            utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
            utterance.rate = speakingRate
            utterance.volume = speakingVolume

            /// synthesizer에서 현재 말하는 중인 경우 즉시 중단한다. (소리가 겹쳐서 들리는 현상 방지)
            stopSpeak()
            synthesizer.speak(utterance)
        }
    }

    func stopSpeak() {
        if (synthesizer.isSpeaking) {
            synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
        }
    }
}
