//
//  SoundManager.swift
//  Oculo
//
//  Created by heojaenyeong on 2022/11/03.
//  Copyright © 2022 Intelligent ATLAS. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class SoundManager {
    /// 출처  https://stackoverflow.com/questions/66145794/avaudioengine-positional-audio-not-working-with-playandrecord-audio-session-cat

    let audioEngine = AVAudioEngine()  /// 오디오 엔진 선언
    let defaultBeep = "defaultBeep.mp3"  /// 출처 https://www.soundjay.com/censor-beep-sound-effect.html
    let audioPlayerNode = AVAudioPlayerNode() /// 오디오 플레어어 노드 선언
    let environmentNode = AVAudioEnvironmentNode()  /// 오디오 환경 노드 선언

    let synthesizer = AVSpeechSynthesizer()
    var speakingRate: Float
    var speakingVolume = Float(1.0)

    /// 대략적인 오디오 엔진 구조 : AVAudioEnvironmentNode -> AVAudioPlayerNode -> 재생의 과정을 거친다.
    /// 여기서 AVAudioEnvironmentNode 노드는 사용자의 위치를, AVAudioPlayerNode는 플레이어의 위치를 설정한다고 생각하면 편하다.

    /// String을 입력 받아 TTS 수행

    init() {
        // MARK: AVAudioSession 설정
        /// 오디오 세션(앱에서 오디오를 사용하는 방식을 시스템에 전잘하는 객체) 선언.
        /// 여기서는 공유된 오디오 세션 인스턴스로 설정
        let audioSession = AVAudioSession.sharedInstance()

        /// 소리 재생 모드. 블루투스 기기와의 연결을 허용하는 오디오 세션 설정
        try! audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetoothA2DP,.defaultToSpeaker])
        try! audioSession.setActive(true)

        // MARK: AVAudioEnvironmentNode 설정
        self.environmentNode.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)  /// 사용자 위치 0, 0, 0 으로 지정
        self.audioEngine.attach(self.environmentNode)  /// AvAudioEngine에 environmentNode 연결
        let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: self.audioEngine.outputNode.outputFormat(forBus: 0).sampleRate, channels: 2)  /// 2채널 스테레오 포맷 생성

        /// environmentNode 을 outputNode에 연결
        self.audioEngine.connect(self.environmentNode, to: self.audioEngine.outputNode, format: stereoFormat)

        /// AVAudioEngine 준비상태로 설정
        self.audioEngine.prepare()

        /// AVAudioEigine 시작
        try! self.audioEngine.start()

        // MARK: AVAudioPlayerNode 설정
        /// audioPlayerNode을 audioEngine에 붙임
        self.audioEngine.attach(self.audioPlayerNode)

        /// 1 채널 모노 포맷 생성 (Spatial Audio 를 위해서는 재생음원이 1채널이어야만 함)
        let monoFormat =  AVAudioFormat(standardFormatWithSampleRate: self.audioEngine.outputNode.outputFormat(forBus: 0).sampleRate, channels: 1)

        /// 위에서 생성한 environmentNode에 audioPlayerNode 연결
        self.audioEngine.connect(self.audioPlayerNode, to: self.environmentNode, format: monoFormat)
        self.audioPlayerNode.renderingAlgorithm = .HRTFHQ  /// 가상 3dPositioning 알고리즘 설정

        if UserDefaults.standard.float(forKey: "speakingRate") != nil {  /// 말하기 속도가 저장되어 있는 경우
            speakingRate = UserDefaults.standard.float(forKey: "speakingRate")  /// User default에서 speakingRate 값을 읽어 와서 soundManager의 speakingRate에 저장
        } else {  /// 말하기 속도가 저장되어 있지 않는 경우
            speakingRate = Float(0.5)  /// speakingRate를 0.5로 저장
        }
    }

    // TODO: 블루투스 재생 뿐 아니라 스피커로 재생하는 방법 필요
    func playBeep(x:Float, y:Float, z:Float,beepSource:String = "defaultBeep.mp3") {
        let defaultBeepUrl = Bundle.main.url(forResource: beepSource, withExtension: nil)  /// defaultBeep URL
        let defaultBeepFile = try! AVAudioFile(forReading: defaultBeepUrl!)  /// defaultBeep의 음원 파일을 읽어 와서
        self.audioPlayerNode.scheduleFile(defaultBeepFile, at: nil, completionHandler: nil)  /// audioPlayerNode에 등록
        
        self.audioPlayerNode.position = AVAudio3DPoint(x: x, y: y, z: z)  /// 소리가 나는 위치 포지셔닝
        self.audioPlayerNode.play()  /// 음원 재생 시작
    }

    func speak(_ string: String) {
        /// VoiceOver와 충돌을 방지하기 위해 VoiceOver가 문장을 읽어 주는 것으로 변경하였습니다.
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .announcement, argument: string)
        } else {
            /// VoiceOver를 사용하지 않는 경우 TTS가 문장을 읽음.
            let utterance = AVSpeechUtterance(string: string)
            if languageSetting == "ko" {
                utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
            } else {
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            }

            utterance.rate = speakingRate
            utterance.volume = speakingVolume

            /// synthesizer에서 현재 말하는 중인 경우 즉시 중단: (소리가 겹쳐서 들리는 현상 방지
            synthesizer.stopSpeaking(at: AVSpeechBoundary.word)
            synthesizer.speak(utterance)
        }
    }

    func speakByTTS(_ string: String) {
        /// TTS가 문장을 읽음
        let utterance = AVSpeechUtterance(string: string)
        if languageSetting == "ko" {
            utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }

        utterance.rate = speakingRate
        utterance.volume = speakingVolume

        /// synthesizer에서 현재 말하는 중인 경우 즉시 중단: 소리가 겹쳐서 들리는 현상 방지
        synthesizer.stopSpeaking(at: AVSpeechBoundary.word)
        synthesizer.speak(utterance)
    }

    func stopSpeak() {
        if (synthesizer.isSpeaking) {
            synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
        }
    }
}
