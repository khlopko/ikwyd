package main

import (
	"crypto/rand"
	"database/sql"
	"encoding/binary"
	"encoding/hex"
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	_ "github.com/tursodatabase/libsql-client-go/libsql"
)

type Log struct {
	Date       string
	Time       string
	CpuUsageP  uint8
	MemUsageMb uint16
}

func parse(payload []byte) Log {
	day := payload[0]
	month := payload[1]
	year := binary.LittleEndian.Uint16(payload[2:4])
	hour := payload[4]
	minute := payload[5]
	second := payload[6]
	cpu := payload[7]
	mem := binary.LittleEndian.Uint16(payload[8:10])
	date := fmt.Sprintf("%.2d%.2d%d", day, month, year)
	time := fmt.Sprintf("%.2d%.2d%.2d", hour, minute, second)
	return Log{date, time, cpu, mem}
}

func save(logs *[]Log, db *sql.DB) {
	var fmtStr string
	for i, log := range *logs {
		fmtStr += fmt.Sprintf("(\"%s\", \"%s\", %d, %d)", log.Date, log.Time, log.CpuUsageP, log.MemUsageMb)
		if i != len(*logs)-1 {
			fmtStr += ", "
		}
	}
	fmtStr = "INSERT INTO logs (date, time, cpu_usage_p, mem_usage_mb) VALUES " + fmtStr[:] + ";"
	db.Exec(fmtStr)
}

func rotterdamHandler(c *gin.Context, db *sql.DB) {
	data, err := c.GetRawData()
	if err != nil {
		c.Data(400, "text/plain", *new([]byte))
		return
	}
	if len(data)%10 != 0 {
		c.Data(400, "text/plain", *new([]byte))
		return
	}
	payload := (data)[:min(len(data), 1024)]
	var logs []Log
	for i := 0; i < len(payload); {
		logs = append(logs, parse(payload[i:i+10]))
		i += 10
	}
	go save(&logs, db)
	c.Data(204, "text/plain", *new([]byte))
}

func generateAPIKey(length int) (string, error) {
	bytes := make([]byte, length)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return hex.EncodeToString(bytes), nil
}

func cli(db *sql.DB) {
	var keyLength int
	flag.IntVar(&keyLength, "length", 32, "The length of the generated API key")
	flag.Parse()
	if flag.Arg(0) != "gen-api-key" {
		return
	}

	apiKey, err := generateAPIKey(keyLength)
	if err != nil {
		log.Fatal(err)
	}
	db.Exec("INSERT INTO api_keys (value) VALUES (?)", apiKey)
	fmt.Println("Generated API Key:", apiKey)
}

func apiAuth(db *sql.DB, key string) bool {
	var count int
	db.QueryRow("SELECT COUNT(*) FROM api_keys WHERE value = ?", key).Scan(&count)
	return count == 1
}

func main() {
	godotenv.Load()
	name := os.Getenv("NAME")
	token := os.Getenv("TOKEN")
	url := fmt.Sprintf("libsql://%s.turso.io?authToken=%s", name, token)
	db, err := sql.Open("libsql", url)
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to open db %s: %s", url, err)
		os.Exit(1)
	}
	defer db.Close()

	if len(os.Args) > 1 {
		cli(db)
	} else {
		r := gin.Default()
		r.POST("/rotterdam", func(c *gin.Context) {
			if !apiAuth(db, c.GetHeader("Authorization")) {
				c.AbortWithStatus(401)
				return
			}
		}, func(c *gin.Context) {
			rotterdamHandler(c, db)
		})
		r.Run()
	}
}
