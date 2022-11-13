//
//  TTSTool.swift
//  Oculo
//
//  Created by Dongjin Jeon on 2022/11/11.
//  Copyright © 2022 Intelligent ATLAS. All rights reserved.
//

import AVFoundation

public class TTSTool {
    /// TTS 기능의 소리 제어
    let synthesizer = AVSpeechSynthesizer()

    /// String을 입력 받아 TTS 수행
    func speak(_ string: String) {
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")

        /// synthesizer에서 현재 말하는 중인 경우 즉시 중단한다. (소리가 겹쳐서 들리는 현상 방지)
        stopSpeak()
        synthesizer.speak(utterance)
    }

    func stopSpeak() {
        if (synthesizer.isSpeaking) {
            synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
        }
    }
}
