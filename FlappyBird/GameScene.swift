//
//  GameScene.swift
//  FlappyBird
//
//  Created by hiroko nagano on 2020/08/21.
//  Copyright © 2020 hiroko.nagano. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var appleNode:SKNode!
    var bird:SKSpriteNode!
    //衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0
    let groundCategory: UInt32 = 1 << 1
    let wallCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    let appleCategory: UInt32 = 1 << 4
    
    //スコア用
    var score = 0
    var applescore = 0
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    var applescoreLabelNode:SKLabelNode!
    let userDefaults:UserDefaults = UserDefaults.standard
    
    
    //SKView上にシーンが表示された時に呼ばれるメソッド
    override func didMove(to view: SKView) {
        
        //重力を判定
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self
        //背景色を設定
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        //スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)
        //壁用のノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        //リンゴ用のノード
        appleNode = SKNode()
        scrollNode.addChild(appleNode)
        //各種スプライトを作成する処理をメソッドに分割
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupApple()
        setupScoreLabel()
        
    }
    
    func playsound() {
        let appleSound = SKAudioNode(fileNamed: "coin05.mp3")
        appleSound.autoplayLooped = false
        let playaction = SKAction.play()
        appleSound.run(playaction)
        self.addChild(appleSound)
    }
    
    
    
    
    
    
    
    
    func setupGround() {
        //地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        //必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        //スクロールするアクションを作成
        //左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
        //元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
        //左にスクロール→元のいちー>左にスクロールを無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        //groundのスプライトを配置する
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)
            //スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2 + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )
            //スプライトにアクションを設定する
            sprite.run(repeatScrollGround)
            //スプライドに物理演算を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            //衝突のカテゴリを設定
            sprite.physicsBody?.categoryBitMask = groundCategory
            //衝突時に動かないようにする
            sprite.physicsBody?.isDynamic = false
            //スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupCloud() {
        //雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed:  "cloud")
        cloudTexture.filteringMode = .nearest
        //必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        //スクロールするアクションを作成
        //左方向に画像一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20)
        //元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        //左にスクロール→元のいちー>左にスクロールを無限に繰り返すアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        //groundのスプライトを配置する
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100
            //スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )
            //スプライトにアニメーションを設定する
            sprite.run(repeatScrollCloud)
            //スプライトを追加する
            scrollNode.addChild(sprite)
            
        }
    }
    
    func setupWall() {
        //壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        //移動する距離を計算
        let movingDistane = CGFloat(self.frame.size.width + wallTexture.size().width)
        //画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistane, y: 0, duration: 4)
        //自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        //二つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        //鳥の画像サイズを習得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        //鳥が通り抜ける隙間の長さを鳥のサイズの３倍とする
        let slit_length = birdSize.height * 3
        //隙間位置の上下の振れ幅を鳥のサイズの３倍とする
        let random_y_range = birdSize.height * 3
        //下の壁のy軸下限位置（中央位置から下方向の最大の振れ幅で下の壁を表示する位置）を計算
        let groundSize = SKTexture(imageNamed: "ground").size()
        let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        let under_wall_lowest_y = center_y - slit_length / 2 - wallTexture.size().height / 2 - random_y_range / 2
        
        //壁を生成するアクションを作成
        let createWallAnimation = SKAction.run({
            //壁関係のノードを乗せるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            wall.zPosition = -50//雲より手前、地面より奥
            
            //0~random_y_rangeまでのランダム値を生成
            let random_y = CGFloat.random(in: 0..<random_y_range)
            
            //Y軸下限にランダムな値を足して、下の壁のY座標を決定
            let under_wall_y = under_wall_lowest_y + random_y
            
            //下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            //スプライトに物理演算を設定する
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            //衝突の時動かないようにする
            under.physicsBody?.isDynamic = false
            
            wall.addChild(under)
            
            //上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x:0, y: under_wall_y + wallTexture.size().height + slit_length)
            //スプライトに物理演算を設定する
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            //衝突の時動かないように
            upper.physicsBody?.isDynamic = false
            
            wall.addChild(upper)
            
            //スコアUP用のノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            
            wall.addChild(scoreNode)
            
            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
            
        })
        
        
        //次の壁作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        //壁を作成→時間待ち→壁を作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
    }
    
    func setupBird() {
        //鳥の画像を2種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        //2種類のテクスチャーを交互に変更するアニメーションを作成
        let textureAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(textureAnimation)
        //スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        //物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        //衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false
        //衝突のカテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory
        //アニメーションを設定
        bird.run(flap)
        //スプライトを追加
        addChild(bird)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 {
            //鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero
            //鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        } else if bird.speed == 0 {
            restart()
        }
    }
    
    //SKPhysicsContactDelegateのメソッド。衝突した時に呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        //ゲームオーバーの時は何もしない
        if scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            //スコアようの物体と衝突した
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            
            //ベストスコア更新か確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
        } else if (contact.bodyA.categoryBitMask & appleCategory) == appleCategory || (contact.bodyB.categoryBitMask & appleCategory) == appleCategory {
            //リンゴと衝突した
            print("AppleScoreUp")
            playsound()
            applescore += 1
            applescoreLabelNode.text = "AppleScore:\(applescore)"
            if contact.bodyA.categoryBitMask == appleCategory {
            contact.bodyA.node!.removeFromParent()
            } else {
              contact.bodyB.node!.removeFromParent()
            }
            
            
            
        } else {
            //壁か地面と衝突した
            print("GameOver")
            //スクロールを停止させる
            scrollNode.speed = 0
            
            bird.physicsBody?.collisionBitMask = groundCategory
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration: 1)
            bird.run(roll, completion: {
                self.bird.speed = 0
            })
        }
    }
    
    func restart() {
        score = 0
        scoreLabelNode.text = "Score:\(score)"
        applescore = 0
        applescoreLabelNode.text = "AppleScore:\(applescore)"
        
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0
        
        wallNode.removeAllChildren()
        appleNode.removeAllChildren()
        bird.speed = 1
        scrollNode.speed = 1
    }
    
    func setupScoreLabel() {
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100
        
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        applescore = 0
        applescoreLabelNode = SKLabelNode()
        applescoreLabelNode.fontColor = UIColor.black
        applescoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        applescoreLabelNode.zPosition = 100
        
        applescoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        applescoreLabelNode.text = "AppleScore:\(applescore)"
        self.addChild(applescoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100
        
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
    }
    
    
    func setupApple() {
        //リンゴの画像を読み込む
        let appleTexture = SKTexture(imageNamed: "apple")
        appleTexture.filteringMode = .nearest
        //移動する距離を計算
        let applemovingDistance = CGFloat(self.frame.size.width + appleTexture.size().width)
        //画面外まで移動するアクションを作成
        let moveApple = SKAction.moveBy(x: -applemovingDistance, y: 0, duration: 11)
        //自身を取り除くアクションを作成
        let removeApple = SKAction.removeFromParent()
        //二つのアニメーションを順に実行するアクションを作成
        let appleAnimation = SKAction.sequence([moveApple, removeApple])
        //鳥の画像サイズを習得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        //リンゴ位置の上下の振れ幅を鳥のサイズの4倍とする
        let random_y_range = birdSize.height * 4
        
        //リンゴのy軸下限位置（中央位置から下方向の最大の振れ幅で下の壁を表示する位置）を計算
        let groundSize = SKTexture(imageNamed: "ground").size()
        let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        let under_apple_lowest_y = center_y - random_y_range / 2
        
        //リンゴを生成するアクションを作成
        let createAppleAnimation = SKAction.run({
            //リンゴのノードを乗せるノードを作成
            let apple = SKNode()
            apple.position = CGPoint(x: self.frame.size.width + appleTexture.size().width / 2, y: 0)
            apple.zPosition = 0//いちばん手前
            
            //0~random_y_rangeまでのランダム値を生成
            let random_y = CGFloat.random(in: 0..<random_y_range)
            
            //Y軸下限にランダムな値を足して、リンゴ下限のY座標を決定
            let under_apple_y = under_apple_lowest_y + random_y
            //リンゴのスプライトを作成
            let underapple = SKSpriteNode(texture: appleTexture)
            underapple.xScale = 0.03
            underapple.yScale = 0.03
            underapple.position = CGPoint(x: 0, y: under_apple_y)
            //物理演算を設定
            underapple.physicsBody = SKPhysicsBody(circleOfRadius: underapple.size.height / 2)
            underapple.physicsBody?.categoryBitMask = self.appleCategory
            underapple.physicsBody?.isDynamic = false
            underapple.physicsBody?.contactTestBitMask = self.birdCategory
            
            apple.addChild(underapple)
            
            
            apple.run(appleAnimation)
            
            self.appleNode.addChild(apple)
            
            
        })
        //次のリンゴ作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        //リンゴを作成→時間待ち→リンゴを作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createAppleAnimation, waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
        
        
    }
}

