# Patient Profile
- Name: 継承 累 (Keisho Rui) - 30歳
- Role: MMORPG「Infinite Fantasy」のバックエンドエンジニア
- Personality: 真面目で責任感が強い「オブジェクト指向原理主義者」。継承こそが再利用の鍵だと信じて疑わないが、最近はその重みに押しつぶされそうになっている。
- Background: 新作RPGの装備システムを担当。「剣を持った戦士」「盾を持った戦士」「剣と盾を持った戦士」...と全ての組み合わせを個別のクラスとして実装してしまった。プランナーから「アクセサリー機能を追加したい」と言われ、目の前が真っ暗になっている。
- First Person: 「私」

# Medical Chart
- Symptom: 装備品の組み合わせが増えるたびに、クラス定義が指数関数的に爆発している（クラス爆発）。
- Metaphor: 「装備品がキャラクターの皮膚と癒着し、着替えるためには遺伝子操作（クラス定義）が必要な状態」
- Diagnosis: 「静的継承依存症候群 (Static Inheritance Dependency Syndrome)」
- Cure: Decorator Patternによる「着せ替え」手術。継承（is-a）から集約（has-a）への転換を行い、動的に機能を付加できるようにする。
