//
//  SoundManager.swift
//  Oculo
//
//  Created by heojaenyeong on 2022/11/03.
//  Copyright © 2022 Intelligent ATLAS. All rights reserved.
//

import Foundation
import AVFoundation
class SoundManager {
    // 코드출처 https://stackoverflow.com/questions/66145794/avaudioengine-positional-audio-not-working-with-playandrecord-audio-session-cat
    let audioEngine = AVAudioEngine()  // 오디오 엔진 선언
    let defaultBeep = "defalutBeep.mp3"  // 출처 https://www.soundjay.com/censor-beep-sound-effect.html
    let audioPlayerNode = AVAudioPlayerNode()
    let environmentNode = AVAudioEnvironmentNode()  // 오디오 환경노드 선언
    init() {
        let audioSession = AVAudioSession.sharedInstance()  // 오디오 세션 선언 (앱에서 오디오를 사용하는방식을 시스템에 전잘하는 객체) , 여기서는 공유된 오디오 세션인스턴스로 설정

        try! audioSession.setCategory(.playAndRecord, mode: .default, options: .allowBluetoothA2DP)// 소리재생모드로, 블루투스기기의 연결을 허용하는 오디오세션 설정
        /*
         Using .playback the positional audio DOES work, however we are not able to record.
         */
        // try! audioSession.setCategory(.playback)

        self.environmentNode.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)  // 사용자의 위치를 0,0,0 으로 지정
        self.audioEngine.attach(self.environmentNode)  // AvAudioEngine 에 environmentNode 연결
        let stereoFormat =  AVAudioFormat(standardFormatWithSampleRate: self.audioEngine.outputNode.outputFormat(forBus: 0).sampleRate, channels: 2)
        //2채널 스테레오 포맷 생성

        self.audioEngine.connect(self.environmentNode, to: self.audioEngine.outputNode, format: stereoFormat)  // environmentNode 을 outputNode에 연결
        self.audioEngine.prepare()  // AVAudioEngine 준비상태로 설정
        try! self.audioEngine.start()  // AVAudioEigine 시작

    }

    // TODO: 블루투스 재생뿐만이아니라 스피커로 재생하는 방법 필요
    func play(x:Float, y:Float, z:Float, TTS:String = "defaultBeep.mp3") {

        self.audioEngine.attach(self.audioPlayerNode)  // audioPlayerNode을 audioEngine에 붙힘
        let monoFormat =  AVAudioFormat(standardFormatWithSampleRate: self.audioEngine.outputNode.outputFormat(forBus: 0).sampleRate, channels: 1) // 1 채널 모노 포맷 생성 (Spatial Audio 를 위해서는 재생음원이 1채널 이어야만 함)
        self.audioEngine.connect(self.audioPlayerNode, to: self.environmentNode, format: monoFormat)  // 위에서 만든 environmentNode에 audioPlayerNode를 연결

        // TODO: defaultBeep.mp3 이 아닐경우 TTS로 읽어주는 기능 작성 필요
        let url = Bundle.main.url(forResource: TTS, withExtension: nil)  // defaultBeep의 URL
        let f = try! AVAudioFile(forReading: url!)  // defaultBeep 의 음원파일을 읽어와서

        self.audioPlayerNode.scheduleFile(f, at: nil, completionHandler: nil)  // audioPlayerNode에 등록
        self.audioPlayerNode.renderingAlgorithm = .HRTFHQ  //가상으로 3dPositioning하는 알고리즘 설정
        self.audioPlayerNode.position = AVAudio3DPoint(x: x, y: y, z: z)  // 소리가나는 위치를 포지셔닝함
        self.audioPlayerNode.play() // 음원 시작
    }

}
