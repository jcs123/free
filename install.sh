#!/bin/bash
cat > /usr/local/bin/ws.py << 'PYEOF'
import socket, threading, select, time
LISTEN = "0.0.0.0"
PORTS = [80,8080,8081]
def handle(c):
    try:
        d=c.recv(8192).decode(errors='ignore')
        if "HTTP" in d: c.send(b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n")
        s=socket.socket(); s.connect(("127.0.0.1",22))
        while True:
            r,_,_=select.select([c,s],[],[],10)
            if c in r:
                dd=c.recv(8192)
                if not dd: break
                s.send(dd)
            if s in r:
                dd=s.recv(8192)
                if not dd: break
                c.send(dd)
    except: pass
for P in PORTS:
    def listen(p):
        ss=socket.socket(); ss.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1); ss.bind((LISTEN,p)); ss.listen(100)
        while True:
            c,a=ss.accept(); threading.Thread(target=handle,args=(c,),daemon=True).start()
    threading.Thread(target=listen,args=(P,),daemon=True).start()
while True: time.sleep(60)
PYEOF
chmod +x /usr/local/bin/ws.py
cat > /etc/systemd/system/sosa-ws.service << EOF
[Unit]
Description=SOSA WS 80
After=network.target
[Service]
ExecStart=/usr/bin/python3 /usr/local/bin/ws.py
Restart=always
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload; systemctl enable sosa-ws; systemctl restart sosa-ws
ufw allow 80,8080,22/tcp 2>/dev/null; iptables -I INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null
useradd -M -s /bin/false sosa-demo -e $(date -d "+30 days" +%Y-%m-%d) 2>/dev/null; echo "sosa-demo:sosa123" | chpasswd
echo "INSTALADO OK"
