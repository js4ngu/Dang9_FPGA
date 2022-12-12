# Dang9_FPGA

[디지털 시스템] 전공과목 프로젝트 - 게임 만들기

## 개발 환경
- Vivado 2018.2
- ZedBoard Zynq Evaluation and Development Kit

## 작동 영상
- [링크](https://youtu.be/6aguoTzoUTY)

## 게임 이름
- 미니 당구

## 게임 규칙
- 노란공 : 플레이어1, 빨간공 : 플레이어2
- 상대방 공을 홀에 집어 넣어야 승리
- 자기 공 들어가면 패배

## 조작법
- 본인 차례에 키패드를 이용하여 발사 각도와 발사 속력을 조절
- 조절 후 발사

## 공 모션
- 당구 역학은 적용하지 못함 (삼각함수 사용X)
- 속력과 각도에 대응하는 x축 속력과 y축 속력 테이블을 만들어 놓음.
  - input : 속력, 각도
  - output : x축 속력, y축 속력
  - 해상도가 5도 단위라서 정지 직전에 직선운동합니다.
- 공끼리 충돌 시 움직이는 공의 속도 정보를 부딪친 공에 그대로 인가.
- 공의 속도는 시간에 비례하여 일정하게 줄어들음.
